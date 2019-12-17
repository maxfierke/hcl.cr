module HCL
  module AST
    class Identifier < Node
      def to_s(io : IO)
        io << source
      end

      def value(ctx : ExpressionContext) : Any
        ctx.lookup_var(to_s)
      end
    end
  end
end
