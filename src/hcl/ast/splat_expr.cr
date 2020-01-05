module HCL
  module AST
    class SplatExpr < Node
      def to_s(io : IO)
        io << "[*]"
      end

      def value(ctx : ExpressionContext) : Any
        raise "BUG: This should not be called, as there is no value to represent."
      end
    end
  end
end
