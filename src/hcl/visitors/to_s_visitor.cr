module HCL
  module Visitors
    class ToSVisitor < Visitor
      @in_quotes = false

      def initialize(@io : IO)
      end

      def visit(node : AST::Block)
        io << node.id
        io << " "

        if node.labels.any?
          node.labels.each do |label|
            label.accept(self)
            io << " "
          end
        end

        io << "{"
        io << "\n" if node.attributes.any? || node.blocks.any?

        indent = "  "

        node.attributes.each do |key, value|
          io << indent
          io << "#{key} = "

          attr_lines = value.to_s.split("\n")
          attr_lines.each do |line|
            if line != ""
              io << indent if line != attr_lines.first
              io << line
              io << "\n"
            end
          end
        end

        if node.blocks.any?
          io << "\n" if node.attributes.any?

          node.blocks.each do |block|
            block_lines = block.to_s.split("\n")
            block_lines.each do |line|
              if line != ""
                io << indent
                io << line
                io << "\n"
              end
            end
          end
        end

        io << "}\n"
      end

      def visit(node : AST::Body)
        node.attributes.each do |key, value|
          io << key
          io << " = "
          value.accept(self)
          io << "\n"
        end

        io << "\n" if node.attributes.any?

        node.blocks.each do |block|
          block.accept(self)
          io << "\n" unless node.blocks.last == block
        end
      end

      def visit(node : AST::CallExpr)
        io << node.id
        io << "("

        node.args.each_with_index do |arg, index|
          arg.accept(self)

          if node.varadic? && index == (node.args.size - 1) && arg.is_a?(AST::Identifier)
            io << "..."
          end
        end

        io << ")"
      end

      def visit(node : AST::CondExpr)
        node.predicate.accept(self)
        io << " ? "
        node.true_expr.accept(self)
        io << " : "
        node.false_expr.accept(self)
      end

      def visit(node : AST::Expression)
        node.children.each do |exp|
          case exp
          when AST::Expression
            io << "("
            exp.accept(self)
            io << ")"
          when AST::Template
            io << "\"" if exp.quoted?
            exp.accept(self)
            io << "\"" if exp.quoted?
          else
            exp.accept(self)
          end
        end
      end

      def visit(node : AST::ForExpr)
        io << node.start_tag
        io << "for "

        if key = node.key_name
          io << key
          io << ", "
        end

        io << node.value_name
        io << " in "
        node.coll_expr.accept(self)
        io << ": "

        if key = node.key_expr
          key.accept(self)
          io << " => "
        end
        node.value_expr.accept(self)

        if cond = node.cond_expr
          io << " if "
          cond.accept(self)
        end

        io << node.end_tag
      end

      def visit(node : AST::GetAttrExpr)
        io << "."
        io << node.attribute_name
      end

      def visit(node : AST::Heredoc)
        io << "<<-"
        io << node.delimiter
        io << "\n"

        indent_size = node.indent_size
        content = node.content
        delimiter = node.delimiter

        if indent_size > 0
          lines = content.to_s.split("\n")
          indent = " " * Math.max(2, indent_size - 2)
          lines.each do |line|
            if line != ""
              io << indent
              io << line
              io << "\n"
            end
          end

          delim_indent = " " * Math.max(0, indent_size - 4)
          io << delim_indent
          io << delimiter
        else
          io << content
          io << delimiter
        end
      end

      def visit(node : AST::Identifier)
        io << node.value
      end

      def visit(node : AST::IndexExpr)
        io << "["
        node.index_exp.accept(self)
        io << "]"
      end

      def visit(node : AST::List)
        io << "["
        node.children.each_with_index do |child, index|
          child.accept(self)

          if index != (node.children.size - 1)
            io << ", "
          end
        end

        io << "]"
      end

      def visit(node : AST::Literal)
        if node.string? && !in_quotes?
          io << "\""
          io << node.source
          io << "\""
        else
          io << node.source
        end
      end

      def visit(node : AST::Map)
        io << "{\n"

        pairs = [] of String

        node.attributes.each do |key, value|
          pairs << "  #{key} = #{value.to_s}"
        end

        io << pairs.join(",\n")
        io << "\n}"
      end

      def visit(node : AST::Number)
        io << node.value
      end

      def visit(node : AST::OpExpr)
        right_operand = node.right_operand
        left_operand = node.left_operand

        if right_operand
          left_operand.accept(self)
          io << " "
          io << node.operator
          io << " "
          right_operand.accept(self)
        else
          io << node.operator
          left_operand.accept(self)
        end
      end

      def visit(node : AST::SplatExpr)
        io << "[*]"
      end

      def visit(node : AST::Template)
        node.children.each do |exp|
          case exp
          when AST::Literal
            self.in_quotes = true
            exp.accept(self)
            self.in_quotes = false
          else
            exp.accept(self)
          end
        end
      end

      def visit(node : AST::TemplateForExpr)
        io << "%{for "

        if key = node.key_name
          io << key
          io << ", "
        end

        io << node.value_name
        io << " in "
        node.coll_expr.accept(self)
        io << "}"
        node.tpl_expr.accept(self)
        io << "%{endfor}"
      end

      def visit(node : AST::TemplateIf)
        io << "%{if "
        node.predicate.accept(self)
        io << "}"
        node.true_tpl.accept(self)

        if false_tpl = node.false_tpl
          io << "%{else}"
          false_tpl.accept(self)
        end

        io << "%{endif}"
      end

      def visit(node : AST::TemplateInterpolation)
        io << "${"
        node.expression.accept(self)
        io << "}"
      end

      def visit(node : AST::Node)
        raise "Unreachable"
      end

      private getter :io
      private getter? :in_quotes
      private setter :in_quotes
    end
  end
end
