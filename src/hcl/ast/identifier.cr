module HCL
  module AST
    class Identifier < Node
      def string : String
        source
      end

      def value(ctx : ExpressionContext) : ValueType
        ctx.lookup_var(string)
      end
    end
  end
end
