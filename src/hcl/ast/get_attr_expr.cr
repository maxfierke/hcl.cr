module HCL
  module AST
    class GetAttrExpr < Node
      @attribute_name : String

      getter :attribute_name

      def initialize(attribute : Identifier, **kwargs)
        super(**kwargs)
        @attribute_name = attribute.name
      end
    end
  end
end
