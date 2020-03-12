module HCL
  module AST
    class TemplateInterpolation < Node
      getter :expression

      def initialize(expression : Expression, **kwargs)
        super(**kwargs)
        @expression = expression
      end

      def as_json(ctx : ExpressionContext) : Any
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(to_s)
        else
          evaluate(ctx)
        end
      end
    end
  end
end
