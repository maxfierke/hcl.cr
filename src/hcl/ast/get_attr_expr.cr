module HCL
  module AST
    class GetAttrExpr < Node
      @attribute_name : String

      getter :attribute_name

      def initialize(attribute : Identifier, **kwargs)
        super(**kwargs)
        @attribute_name = attribute.to_s
      end

      def to_s(io : IO)
        io << "."
        io << attribute_name
      end

      def value(ctx : ExpressionContext) : Any
        raise "BUG: This should not be called, as there is no value to represent."
      end
    end
  end
end
