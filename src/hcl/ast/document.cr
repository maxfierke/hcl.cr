module HCL
  module AST
    class Document < Body
      def unwrap
        unwrap(ExpressionContext.default_context)
      end

      def unwrap(ctx : ExpressionContext)
        evaluate(ctx).unwrap
      end

      def evaluate
        evaluate(ExpressionContext.default_context)
      end
    end
  end
end
