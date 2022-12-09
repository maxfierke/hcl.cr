module HCL
  module Visitors
    class Evaluator < Visitor
      getter :ctx

      def initialize(@ctx : ExpressionContext)
      end

      def visit(node : AST::Block)
        labels = node.labels
        block_header = Array(Any).new(labels.size + 1).tap do |arr|
          arr << Any.new(node.id)
          labels.each do |label|
            arr << label.accept(self)
          end

          arr
        end

        block_value = visit_body(node)
        block_header.reverse.reduce(block_value) do |acc, val|
          Any.new({val.to_s => acc})
        end
      end

      def visit(node : AST::Body)
        visit_body(node)
      end

      def visit(node : AST::CallExpr)
        call_args = node.args.map { |arg| arg.accept(self).as(Any) }

        if node.varadic?
          varadic_args = call_args.pop.raw

          if !varadic_args.is_a?(Array(Any))
            raise "Expected varadic argument to evaluate to a list"
          end

          varadic_args.map(&.raw).each { |arg| call_args << Any.new(arg) }
        end

        ctx.call_func(node.id, call_args)
      end

      def visit(node : AST::CondExpr)
        predicate_value = node.predicate.accept(self).raw

        # TODO: validate "correctness" of both expressions to catch errors in
        # HCL construction, if even not for the active path

        if truthy?(predicate_value)
          node.true_expr.accept(self)
        else
          node.false_expr.accept(self)
        end
      end

      def visit(node : AST::Expression)
        node.children.reduce(HCL::Any.new(nil)) do |result, child|
          current = result ? result.raw : nil
          next_val = nil
          if child.is_a?(AST::GetAttrExpr)
            if !current
              raise "Cannot read attribute #{child.attribute_name} from null"
            elsif current.is_a?(Hash)
              attr = current[child.attribute_name].raw
              next_val = attr
            elsif current.is_a?(Array)
              # Handles splat
              next_val = current.map { |item| item[child.attribute_name] }
            else
              raise "Cannot read attribute #{child.attribute_name} from #{current.class}"
            end
          elsif child.is_a?(AST::IndexExpr)
            child_val = child.index_exp.accept(self).raw

            if !current
              raise "Cannot read member #{child_val} from null"
            elsif child_val.is_a?(String) && current.is_a?(Hash)
              attr = current[child_val].raw
              next_val = attr
            elsif child_val.is_a?(Int64) && current.is_a?(Array)
              attr = current[child_val].raw
              next_val = attr
            else
              raise "Cannot read member #{child_val} from #{current.class}"
            end
          elsif child.is_a?(AST::SplatExpr)
            if !current
              raise "Cannot perform splat on null"
            elsif current.is_a?(Array)
              attr = current
              next_val = attr
            else
              raise "Cannot perform splat on #{current.class}"
            end
          else
            next_val = child.accept(self).raw
          end

          HCL::Any.new(next_val)
        end
      end

      def visit(node : AST::ForExpr)
        coll_expr = node.coll_expr
        coll_val = coll_expr.accept(self)
        value_expr = node.value_expr

        if node.is_map_type?
          coll = coll_val.as_h? || coll_val.as_a
          key_expr = node.key_expr.not_nil!

          index = 0
          mapped = coll.reduce(Hash(String, Any).new) do |acc, item|
            if item.is_a?(Tuple)
              key, value = item
            else
              key = index.to_i64
              value = item
            end

            iter_ctx = ExpressionContext.new(ctx)

            if key_name = node.key_name
              iter_ctx.variables[key_name] = Any.new(key)
            end

            iter_ctx.variables[node.value_name] = value
            iter_eval_visitor = Visitors::Evaluator.new(iter_ctx)

            if cond = node.cond_expr
              if cond.accept(iter_eval_visitor).as_bool?
                key_val = key_expr.accept(iter_eval_visitor).to_s
                acc[key_val] = value_expr.accept(iter_eval_visitor)
              end
            else
              key_val = key_expr.accept(iter_eval_visitor).to_s
              acc[key_val] = value_expr.accept(iter_eval_visitor)
            end

            index += 1

            acc
          end

          Any.new(mapped)
        else
          coll = coll_val.as_a

          index = 0
          mapped = coll.reduce(coll.class.new) do |acc, item|
            iter_ctx = ExpressionContext.new(ctx)
            iter_ctx.variables[node.value_name] = item
            if key = node.key_name
              iter_ctx.variables[key] = Any.new(index.to_i64)
            end

            iter_eval_visitor = Visitors::Evaluator.new(iter_ctx)

            if cond = node.cond_expr
              if cond.accept(iter_eval_visitor).as_bool?
                acc << value_expr.accept(iter_eval_visitor)
              end
            else
              acc << value_expr.accept(iter_eval_visitor)
            end

            index += 1

            acc
          end

          Any.new(mapped)
        end
      end

      def visit(node : AST::Heredoc)
        node.content.accept(self)
      end

      def visit(node : AST::Identifier)
        ctx.lookup_var(node.name)
      end

      def visit(node : AST::List)
        result = node.children.map do |item|
          item.accept(self).as(Any)
        end

        Any.new(result)
      end

      def visit(node : AST::Literal)
        Any.new(node.value)
      end

      def visit(node : AST::Map)
        dict = {} of String => Any

        node.attributes.each do |key, value|
          dict[key] = value.accept(self)
        end

        Any.new(dict)
      end

      def visit(node : AST::Number)
        Any.new(node.value)
      end

      def visit(node : AST::OpExpr)
        # This is wrong. Need to figure out order of operations stuff, probably.
        left_operand = node.left_operand
        left_op_val = left_operand.accept(self).raw

        right_operand = node.right_operand
        op = node.operator
        if right_operand.nil?
          raise "Parser bug: Cannot perform unary operation on array" if left_op_val.responds_to?(:[])
          result = case op
                   when AST::OpExpr::NOT
                     !left_op_val
                   when AST::OpExpr::SUBTRACTION
                     raise "Parser bug: Cannot perform numeric inversion on nil" if left_op_val.nil?
                     raise "Parser bug: Cannot perform numeric inversion on boolean" if left_op_val.is_a?(Bool)
                     -left_op_val
                   else
                     raise "BUG: unsupported operator: #{op}"
                   end

          Any.new(result)
        else
          right_op_val = right_operand.accept(self).raw
          result = case op
                   when AST::OpExpr::ADDITION
                     left_op_val, right_op_val = assert_math_op_types!(op, left_op_val, right_op_val)
                     if left_op_val.is_a?(BigDecimal) || right_op_val.is_a?(BigDecimal)
                       left_op_val.to_big_d + right_op_val.to_big_d
                     else
                       left_op_val + right_op_val
                     end
                   when AST::OpExpr::SUBTRACTION
                     left_op_val, right_op_val = assert_math_op_types!(op, left_op_val, right_op_val)
                     if left_op_val.is_a?(BigDecimal) || right_op_val.is_a?(BigDecimal)
                       left_op_val.to_big_d - right_op_val.to_big_d
                     else
                       left_op_val - right_op_val
                     end
                   when AST::OpExpr::MULTIPLY
                     left_op_val, right_op_val = assert_math_op_types!(op, left_op_val, right_op_val)
                     if left_op_val.is_a?(BigDecimal) || right_op_val.is_a?(BigDecimal)
                       left_op_val.to_big_d * right_op_val.to_big_d
                     else
                       left_op_val * right_op_val
                     end
                   when AST::OpExpr::DIVIDE
                     left_op_val, right_op_val = assert_math_op_types!(op, left_op_val, right_op_val)
                     if left_op_val.is_a?(BigDecimal) || right_op_val.is_a?(BigDecimal)
                       left_op_val.to_big_d / right_op_val.to_big_d
                     else
                       left_op_val / right_op_val
                     end
                   when AST::OpExpr::MOD
                     left_op_val, right_op_val = assert_math_op_types!(op, left_op_val, right_op_val)
                     if left_op_val.is_a?(Float64) && right_op_val.is_a?(Float64)
                       left_op_val % right_op_val
                     elsif left_op_val.is_a?(Int64) && right_op_val.is_a?(Int64)
                       left_op_val % right_op_val
                     else
                       raise "Parser bug: Cannot perform modulo operation on different types"
                     end
                   when AST::OpExpr::EQ
                     left_op_val, right_op_val = assert_eq_types!(op, left_op_val, right_op_val)
                     left_op_val == right_op_val
                   when AST::OpExpr::NEQ
                     left_op_val, right_op_val = assert_eq_types!(op, left_op_val, right_op_val)
                     left_op_val != right_op_val
                   when AST::OpExpr::LT
                     left_op_val, right_op_val = assert_comp_types!(op, left_op_val, right_op_val)
                     left_op_val < right_op_val
                   when AST::OpExpr::GT
                     left_op_val, right_op_val = assert_comp_types!(op, left_op_val, right_op_val)
                     left_op_val > right_op_val
                   when AST::OpExpr::LTE
                     left_op_val, right_op_val = assert_comp_types!(op, left_op_val, right_op_val)
                     left_op_val <= right_op_val
                   when AST::OpExpr::GTE
                     left_op_val, right_op_val = assert_comp_types!(op, left_op_val, right_op_val)
                     left_op_val >= right_op_val
                   when AST::OpExpr::AND
                     left_op_val && right_op_val
                   when AST::OpExpr::OR
                     left_op_val || right_op_val
                   else
                     raise "BUG: unsupported operator: #{op}"
                   end

          Any.new(result)
        end
      end

      def visit(node : AST::Template)
        children = node.children
        if children.size == 1
          children.first.accept(self)
        else
          builder = String.build do |str|
            children.each do |exp|
              # TODO: Validate stringiness
              str << exp.accept(self).to_s
            end
          end

          Any.new(builder.to_s)
        end
      end

      def visit(node : AST::TemplateForExpr)
        coll_expr = node.coll_expr
        coll_val = coll_expr.accept(self)
        coll = coll_val.as_h? || coll_val.as_a

        index = 0

        builder = String.build do |str|
          coll.each do |item|
            if item.is_a?(Tuple)
              key, value = item
            else
              key = index.to_i64
              value = item
            end

            iter_ctx = ExpressionContext.new(ctx)

            if key_name = node.key_name
              iter_ctx.variables[key_name] = Any.new(key)
            end

            iter_ctx.variables[node.value_name] = value

            tpl_eval_visitor = Visitors::Evaluator.new(iter_ctx)
            tpl_expr_val = node.tpl_expr.accept(tpl_eval_visitor)

            str << tpl_expr_val.to_s
          end
        end

        Any.new(builder.to_s)
      end

      def visit(node : AST::TemplateIf)
        predicate_value = node.predicate.accept(self).raw

        # TODO: validate "correctness" of both expressions to catch errors in
        # HCL construction, if even not for the active path

        if truthy?(predicate_value)
          node.true_tpl.accept(self)
        elsif false_tpl = node.false_tpl
          false_tpl.accept(self)
        else
          Any.new("")
        end
      end

      def visit(node : AST::TemplateInterpolation)
        node.expression.accept(self)
      end

      def visit(node : AST::Node)
        raise "Unreachable"
      end

      private def assert_math_op_types!(op, left_op_val, right_op_val)
        raise "Parser bug: Cannot perform #{op} operation on array" if left_op_val.is_a?(Array)
        raise "Parser bug: Cannot perform #{op} operation on array" if right_op_val.is_a?(Array)
        raise "Parser bug: Cannot perform #{op} operation on boolean" if left_op_val.is_a?(Bool)
        raise "Parser bug: Cannot perform #{op} operation on boolean" if right_op_val.is_a?(Bool)
        raise "Parser bug: Cannot perform #{op} operation on hash" if left_op_val.is_a?(Hash)
        raise "Parser bug: Cannot perform #{op} operation on hash" if right_op_val.is_a?(Hash)
        raise "Parser bug: Cannot perform #{op} operation on string" if left_op_val.is_a?(String)
        raise "Parser bug: Cannot perform #{op} operation on string" if right_op_val.is_a?(String)
        raise "Parser bug: Cannot perform #{op} operation on nil" if left_op_val.nil?
        raise "Parser bug: Cannot perform #{op} operation on nil" if right_op_val.nil?
        {left_op_val, right_op_val}
      end

      private def assert_eq_types!(op, left_op_val, right_op_val)
        raise "Parser bug: Cannot perform #{op} operation on array" if left_op_val.is_a?(Array)
        raise "Parser bug: Cannot perform #{op} operation on array" if right_op_val.is_a?(Array)
        raise "Parser bug: Cannot perform #{op} operation on hash" if left_op_val.is_a?(Hash)
        raise "Parser bug: Cannot perform #{op} operation on hash" if right_op_val.is_a?(Hash)
        {left_op_val, right_op_val}
      end

      private def assert_comp_types!(op, left_op_val, right_op_val)
        raise "Parser bug: Cannot perform #{op} comparision on bool" if left_op_val.is_a?(Bool) || right_op_val.is_a?(Bool)
        raise "Parser bug: Cannot perform #{op} comparision on string" if left_op_val.is_a?(String) || right_op_val.is_a?(String)
        raise "Parser bug: Cannot perform #{op} comparision on null" if left_op_val.nil? || right_op_val.nil?
        assert_eq_types!(op, left_op_val, right_op_val)
      end

      protected def deep_merge_blocks!(dict, other_dict)
        dict.merge!(other_dict) do |key, v1, v2|
          if (v1_arr = v1.as_a?) && (v2_arr = v2.as_a?)
            Any.new(v1_arr + v2_arr)
          elsif v1_arr = v1.as_a?
            v1_arr << v2
            Any.new(v1_arr)
          elsif v2_arr = v2.as_a?
            v2_arr.unshift(v1)
            Any.new(v2_arr)
          elsif (v1_hsh = v1.as_h?) && (v2_hsh = v2.as_h?)
            Any.new(
              deep_merge_blocks!(v1_hsh, v2_hsh)
            )
          else
            v2
          end
        end
      end

      # TODO: Verify these invariants
      private def truthy?(val : Int64)
        val != 0
      end

      private def truthy?(val : String)
        val != ""
      end

      private def truthy?(val)
        !!val
      end

      private def visit_body(node : AST::Body)
        dict = {} of String => Any

        node.attributes.each do |key, value|
          dict[key] = value.accept(self)
        end

        node.blocks.each do |block|
          block_dict = block.accept(self).as_h
          deep_merge_blocks!(dict, block_dict)
        end

        Any.new(dict)
      end
    end
  end
end
