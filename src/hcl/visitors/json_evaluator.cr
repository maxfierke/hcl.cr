module HCL
  module Visitors
    class JsonEvaluator < Evaluator
      getter :ctx

      def initialize(@ctx : ExpressionContext)
      end

      def visit(node : AST::CallExpr)
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(node.to_s)
        else
          super(node)
        end
      end

      def visit(node : AST::CondExpr)
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(node.to_s)
        else
          super(node)
        end
      end

      def visit(node : AST::Expression)
        children = node.children

        if children.size == 1
          child = children.first.not_nil!
          case child
          when AST::Expression,
               AST::List,
               AST::Map,
               AST::Number,
               AST::Template
            return child.accept(self)
          else
            # Continue
          end
        end

        if ctx.literal_only?
          Any.new("${#{node.to_s}}")
        else
          Any.new(node.to_s)
        end
      end

      def visit(node : AST::ForExpr)
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(node.to_s)
        else
          super(node)
        end
      end

      def visit(node : AST::GetAttrExpr)
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(node.to_s)
        else
          super(node)
        end
      end

      def visit(node : AST::Heredoc)
        content = node.content
        indent_size = node.indent_size

        json_heredoc = String.build do |str|
          if indent_size > 0
            lines = content.to_s.split("\n")
            indent = " " * Math.max(2, indent_size - 2)
            lines.each do |line|
              if line != ""
                str << indent
                str << line
                str << "\\n"
              end
            end
          else
            str << content
          end
        end

        Any.new(json_heredoc.to_s)
      end

      def visit(node : AST::Identifier)
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(node.to_s)
        else
          super(node)
        end
      end

      def visit(node : AST::IndexExpr)
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(node.to_s)
        else
          super(node)
        end
      end

      def visit(node : AST::OpExpr)
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(node.to_s)
        else
          super(node)
        end
      end

      def visit(node : AST::SplatExpr)
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(node.to_s)
        else
          super(node)
        end
      end

      def visit(node : AST::TemplateForExpr)
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(node.to_s)
        else
          super(node)
        end
      end

      def visit(node : AST::TemplateIf)
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(node.to_s)
        else
          super(node)
        end
      end

      def visit(node : AST::TemplateInterpolation)
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(node.to_s)
        else
          super(node)
        end
      end

      def visit(node : AST::Template)
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(node.to_s)
        else
          super(node)
        end
      end
    end
  end
end
