module HCL
  module AST
    class Document < Body
      def unwrap
        unwrap(ExpressionContext.default_context)
      end

      def unwrap(ctx : ExpressionContext)
        value(ctx).unwrap
      end

      def value
        value(ExpressionContext.default_context)
      end
    end
  end
end
