module HCL
  module AST
    class TemplateInterpolation < Node
      getter :expression

      def initialize(expression : Expression, **kwargs)
        super(**kwargs)
        @expression = expression
      end

      def to_s(io : IO)
        io << "${"
        expression.to_s(io)
        io << "}"
      end

      def value(ctx : ExpressionContext) : Any
        expression.value(ctx)
      end
    end
  end
end
