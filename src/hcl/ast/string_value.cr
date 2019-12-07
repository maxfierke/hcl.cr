module HCL
  module AST
    class StringValue < Node
      def to_s(io : IO)
        io << "\""
        io << source
        io << "\""
      end

      def value(ctx : ExpressionContext) : ValueType
        source
      end
    end
  end
end
