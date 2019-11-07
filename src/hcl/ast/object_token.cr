module HCL
  module AST
    class ObjectToken < ValueToken
      getter :values

      def initialize(
        peg_tuple : Pegmatite::Token,
        source : String,
        values : Hash(String, ValueToken)
      )
        super(peg_tuple, source)

        @values = values
      end

      def string
        String.build do |str|
          str << "{ "

          pairs = [] of String

          values.each do |key, value|
            pairs << "#{key} = #{value.string}"
          end

          str << pairs.join(", ")
          str << " }"
        end
      end

      def value : ValueType
        dict = {} of String => ValueType

        values.each do |key, value|
          dict[key] = value.value
        end

        dict
      end
    end
  end
end
