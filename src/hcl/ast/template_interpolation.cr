module HCL
  module AST
    class TemplateInterpolation < Node
      getter :expression

      def initialize(expression : Expression, **kwargs)
        super(**kwargs)
        @expression = expression
      end

      def value(ctx : ExpressionContext) : Any
        expression.value(ctx)
      end
    end
  end
end
