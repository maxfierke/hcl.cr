module HCL
  module AST
    class GetAttrToken < ValueToken
      @attribute_name : String

      getter :attribute_name

      def initialize(
        peg_tuple : Pegmatite::Token,
        source : String,
        attribute : IdentifierToken
      )
        super(peg_tuple, source)

        @attribute_name = attribute.string
      end

      def string
        ".#{attribute_name}"
      end

      def value : ValueType
        raise "BUG: This should not be called, as there is no value to represent."
      end
    end
  end
end
