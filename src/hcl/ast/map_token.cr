module HCL
  module AST
    class MapToken < ValueToken
      getter :values

      def initialize(
        peg_tuple : Pegmatite::Token,
        string : String,
        values : Hash(String, ValueToken)
      )
        super(peg_tuple, string)

        @values = values
      end

      def value
        dict = {} of String => ValueType

        values.each do |key, value|
          dict[key] = value.value
        end

        dict
      end
    end
  end
end
