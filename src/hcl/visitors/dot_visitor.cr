module HCL
  module Visitors
    class DotVisitor < Visitor
      @last_node_id = 1
      @node_ids = Hash(AST::Node, Int32).new

      def initialize(@name : String, @io : IO)
      end

      def visit(node : AST::Document)
        io << "digraph #{@name} {\n"
        io << "  rankdir=LR;\n"
        io << "  node [shape=circle];\n"

        write_node(node)

        node.attributes.each do |key, value|
          write_node(node, value, label: key)
          value.accept(self)
        end

        node.blocks.each do |block|
          write_node(node, block)
          block.accept(self)
        end

        io << "}\n"
      end

      def visit(node : AST::Block)
        write_node(node, label: node.id)

        node.labels.each do |label|
          write_node(node, label)
          label.accept(self)
        end

        node.attributes.each do |key, value|
          write_node(node, value, label: key)
          value.accept(self)
        end

        node.blocks.each do |block|
          write_node(node, block)
          block.accept(self)
        end
      end

      def visit(node : AST::Body)
        write_node(node)

        node.attributes.each do |key, value|
          write_node(node, value, label: key)
          value.accept(self)
        end

        node.blocks.each do |block|
          write_node(node, block)
          block.accept(self)
        end
      end

      def visit(node : AST::CallExpr)
        write_node(node, label: "#{node.id}()")

        node.args.each_with_index do |arg, index|
          write_node(node, arg, label: "arg#{index}")
          arg.accept(self)
        end
      end

      def visit(node : AST::CondExpr)
        write_node(node)
        write_node(node, node.predicate, label: "Predicate")
        node.predicate.accept(self)

        write_node(node, node.true_expr, label: "TrueExpr")
        node.true_expr.accept(self)
        write_node(node, node.false_expr, label: "FalseExpr")
        node.false_expr.accept(self)
      end

      def visit(node : AST::Expression)
        write_node(node)

        node.children.each do |exp|
          write_node(node, exp)
        end
      end

      # def visit(node : AST::ForExpr)
      #   io << node.start_tag
      #   io << "for "

      #   if key = node.key_name
      #     io << key
      #     io << ", "
      #   end

      #   io << node.value_name
      #   io << " in "
      #   node.coll_expr.accept(self)
      #   io << ": "

      #   if key = node.key_expr
      #     key.accept(self)
      #     io << " => "
      #   end
      #   node.value_expr.accept(self)

      #   if cond = node.cond_expr
      #     io << " if "
      #     cond.accept(self)
      #   end

      #   io << node.end_tag
      # end

      def visit(node : AST::GetAttrExpr)
        write_node(node, label: ".#{node.attribute_name}")
      end

      def visit(node : AST::Heredoc)
        write_node(node, label: node.delimiter)
      end

      def visit(node : AST::Identifier)
        write_node(node, label: node.name)
      end

      def visit(node : AST::IndexExpr)
        write_node(node, label: "[]")
        write_node(node, node.index_exp)
        node.index_exp.accept(self)
      end

      def visit(node : AST::List)
        write_node(node)

        node.children.each do |child|
          write_node(node, child)
          child.accept(self)
        end
      end

      def visit(node : AST::Literal)
        if node.string?
          write_node(node, label: "\\\"#{node.source}\\\"")
        else
          write_node(node, label: node.source)
        end
      end

      def visit(node : AST::Map)
        write_node(node)

        node.attributes.each do |key, value|
          write_node(node, value, label: key)
          value.accept(self)
        end
      end

      def visit(node : AST::Number)
        write_node(node, label: node.value.to_s)
      end

      def visit(node : AST::OpExpr)
        right_operand = node.right_operand
        left_operand = node.left_operand

        write_node(node, label: node.operator.to_s)
        write_node(node, left_operand)
        left_operand.accept(self)

        if right_operand
          write_node(node, right_operand)
          right_operand.accept(self)
        end
      end

      def visit(node : AST::SplatExpr)
        write_node(node, label: "[*]")
      end

      def visit(node : AST::Template)
        write_node(node)

        node.children.each do |exp|
          write_node(node, exp)
          exp.accept(self)
        end
      end

      # def visit(node : AST::TemplateForExpr)
      #   write_node(node, )

      #   io << "%{for "

      #   if key = node.key_name
      #     io << key
      #     io << ", "
      #   end

      #   io << node.value_name
      #   io << " in "
      #   node.coll_expr.accept(self)
      #   io << "}"
      #   node.tpl_expr.accept(self)
      #   io << "%{endfor}"
      # end

      # def visit(node : AST::TemplateIf)
      #   io << "%{if "
      #   node.predicate.accept(self)
      #   io << "}"
      #   node.true_tpl.accept(self)

      #   if false_tpl = node.false_tpl
      #     io << "%{else}"
      #     false_tpl.accept(self)
      #   end

      #   io << "%{endif}"
      # end

      def visit(node : AST::TemplateInterpolation)
        write_node(node, label: "${}")
        write_node(node, node.expression)
        node.expression.accept(self)
      end

      def visit(node : AST::Node)
        write_node(node)
      end

      private getter :io

      private def write_node(node, child : AST::Node? = nil, label : String? = nil)
        if child
          io << "#{node_id(node)} -> #{node_id(child)}"
        else
          io << node_id(node)
        end

        if label
          io << " [label=\"#{label}\"]"
        else
          io << " [label=\"#{child ? child.class : node.class}\"]"
        end

        io << "\n"
      end

      private def node_id(node)
        if node_id = @node_ids[node]?
          node_id
        else
          next_node_id = @last_node_id + 1
          @node_ids[node] = next_node_id
          @last_node_id = next_node_id
          next_node_id
        end
      end
    end
  end
end
