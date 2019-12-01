module HCL
  class Parser
    @nodes : Nil | Array(AST::Node)

    include Iterator(AST::Node)

    getter :source

    def initialize(@source : String, offset = 0, io : IO? = nil)
      @peg_tokens = Pegmatite.tokenize(HCL::Grammar, source, offset, io)
      @peg_iter = Pegmatite::TokenIterator.new(@peg_tokens)
    end

    def parse
      nodes
    end

    def nodes
      @nodes ||= to_a
    end

    def string
      nodes.map { |token| token.string }.join('\n')
    end

    def values
      nodes.map { |token| token.value }
    end

    def next
      if peg_main = @peg_iter.peek
        @peg_iter.next
        build_node(peg_main, @peg_iter, source)
      else
        stop
      end
    end

    private def build_node(main, iter, source) : AST::Node
      kind, start, finish = main

      # Build the node from the given main token and possibly further recursion.
      value =
        case kind
        when :block then build_block(main, iter, source)
        when :conditional then build_conditional(main, iter, source)
        when :expression then build_expression(main, iter, source)
        when :function_call then build_call(main, iter, source)
        when :get_attr then build_get_attr(main, iter, source)
        when :identifier then AST::Identifier.new(main, source[start...finish])
        when :index then build_index(main, iter, source)
        when :literal then AST::Literal.new(main, source[start...finish])
        when :number then AST::Number.new(main, source[start...finish])
        when :object then build_map(main, iter, source)
        when :operation then build_operation(main, iter, source)
        when :string then AST::StringValue.new(main, source[start...finish])
        when :tuple then build_list(main, iter, source)
        else raise NotImplementedError.new(kind)
        end

      # Assert that we have consumed all child tokens.
      iter.assert_next_not_child_of(main)

      value
    end

    private def build_conditional(main, iter, source) : AST::CondExpr
      _, start, finish = main

      predicate = iter.next_as_child_of(main)
      predicate_node = build_node(predicate, iter, source).as(AST::Expression)

      true_expr = iter.next_as_child_of(main)
      true_expr_node = build_node(true_expr, iter, source).as(AST::Expression)

      false_expr = iter.next_as_child_of(main)
      false_expr_node = build_node(false_expr, iter, source).as(AST::Expression)

      AST::CondExpr.new(
        main,
        source[start...finish],
        predicate_node,
        true_expr_node,
        false_expr_node
      )
    end

    private def build_expression(main, iter, source) : AST::Expression
      _, start, finish = main

      exp_terms = [] of AST::Node

      # TODO: This is wrong, but not settled on what this *is* yet.
      context = HCL::ExpressionContext.new

      iter.while_next_is_child_of(main) do |child|
        exp_terms << build_node(child, iter, source)
      end

      unless exp_terms.any?
        raise "BUG: expected expression to have content"
      end

      AST::Expression.new(
        main,
        source[start...finish],
        exp_terms,
        context
      )
    end

    private def build_get_attr(main, iter, source) : AST::GetAttrExpr
      _, start, finish = main

      next_token = iter.next_as_child_of(main)
      kind, _, _ = next_token

      if kind != :identifier
        raise "BUG: expected identifier, got #{kind}"
      end

      identifier_node = build_node(next_token, iter, source).as(AST::Identifier)

      AST::GetAttrExpr.new(
        main,
        source[start...finish],
        identifier_node
      )
    end

    private def build_index(main, iter, source) : AST::IndexExpr
      _, start, finish = main

      next_token = iter.next_as_child_of(main)
      kind, _, _ = next_token

      if kind != :expression
        raise "BUG: expected expression, got #{kind}"
      end

      expr_node = build_node(next_token, iter, source).as(AST::Expression)

      AST::IndexExpr.new(
        main,
        source[start...finish],
        expr_node
      )
    end

    private def build_operation(main, iter, source) : AST::OpExpr
      _, start, finish = main

      # TODO: This is wrong, but not settled on what this *is* yet.
      context = HCL::ExpressionContext.new

      next_token = iter.peek_as_child_of(main)

      unless next_token
        raise "BUG: expected 'next_token' to not be nil"
      end

      kind, _, _ = next_token

      if kind == :operator
        operator = iter.next_as_child_of(main)
        left_operand = iter.next_as_child_of(main)
        left_operand_node = build_node(left_operand, iter, source)
        right_operand_node = nil
      elsif kind == :number || kind == :literal
        left_operand = iter.next_as_child_of(main)
        left_operand_node = build_node(left_operand, iter, source)
        operator = iter.next_as_child_of(main)
        right_operand = iter.next_as_child_of(main)
        right_operand_node = build_node(right_operand, iter, source)
      else
        raise "BUG: Expected operator, number, or literal, but got #{kind}"
      end

      _, op_start, op_finish = operator

      AST::OpExpr.new(
        main,
        source[start...finish],
        source[op_start...op_finish],
        left_operand_node,
        right_operand_node
      )
    end

    private def build_list(main, iter, source) : AST::List
      _, start, finish = main
      list = AST::List.new(main, source[start...finish])

      # Gather children as values into the list.
      iter.while_next_is_child_of(main) do |child|
        list << build_node(child, iter, source)
      end

      list
    end

    private def extract_identifier(main, iter, source)
      kind, start, finish = main

      if kind != :identifier
        raise "Expected identifer, but got #{kind}"
      end

      source[start...finish]
    end

    private def build_map(main, iter, source) : AST::Map
      kind, start, finish = main

      if kind != :object
        raise "Expected object, but got '#{kind}'"
      end

      values = {} of String => AST::Node

      iter.while_next_is_child_of(main) do |token|
        kind, _, _ = token

        if kind == :attribute
          # Gather children as pairs of key/values into the object.
          key = build_node(iter.next_as_child_of(token), iter, source).as_s
          val = build_node(iter.next_as_child_of(token), iter, source)
          iter.assert_next_not_child_of(token)
          values[key] = val
        else
          raise "'#{kind}' is not supported within objects."
        end
      end

      AST::Map.new(
        main,
        source[start...finish],
        values
      )
    end

    private def build_block(main, iter, source) : AST::Block
      _, start, finish = main
      block_attributes = {} of String => AST::Node
      block_labels = Array(AST::Identifier | AST::StringValue).new
      blocks = [] of AST::Block

      block_id = extract_identifier(iter.next_as_child_of(main), iter, source)

      has_seen_seen_inner_block = false

      iter.while_next_is_child_of(main) do |token|
        kind, _, _ = token

        if kind == :attribute
          has_seen_seen_inner_block = true
          # Gather children as pairs of key/values into the array.
          key = build_node(iter.next_as_child_of(token), iter, source).as_s
          val = build_node(iter.next_as_child_of(token), iter, source)
          iter.assert_next_not_child_of(token)
          block_attributes[key] = val
        elsif kind == :block
          has_seen_seen_inner_block = true
          new_block = build_block(token, iter, source)
          iter.assert_next_not_child_of(token)
          blocks << new_block
        elsif kind == :identifier || kind == :string
          if has_seen_seen_inner_block
            raise "Found '#{kind}' but expected an attribute assignment or block."
          else
            label_node = build_node(token, iter, source)

            if kind == :identifier
              block_labels << label_node.as(AST::Identifier)
            elsif kind == :string
              block_labels << label_node.as(AST::StringValue)
            else
              raise "BUG: Should be identifier or string"
            end
          end
        else
          pp! token
          raise "'#{kind}' is not supported within blocks."
        end
      end

      AST::Block.new(
        main,
        source[start...finish],
        block_id,
        block_labels,
        block_attributes,
        blocks
      )
    end

    private def build_call(main, iter, source) : AST::CallExpr
      _, start, finish = main
      args = [] of AST::Node

      function_id = extract_identifier(iter.next_as_child_of(main), iter, source)

      next_token = iter.next_as_child_of(main)
      kind, _, _ = next_token

      if kind != :arguments
        raise "Expected arguments, but got '#{kind}'"
      end

      iter.while_next_is_child_of(next_token) do |child|
        args << build_node(child, iter, source)
      end

      AST::CallExpr.new(
        main,
        source[start...finish],
        function_id,
        args
      )
    end
  end
end
