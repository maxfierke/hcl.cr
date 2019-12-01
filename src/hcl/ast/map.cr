module HCL
  module AST
    class Map < Node
      getter :attributes

      def initialize(
        peg_tuple : Pegmatite::Token,
        source : String,
        attributes : Hash(String, Node)
      )
        super(peg_tuple, source)

        @attributes = attributes
      end

      def string : String
        String.build do |str|
          str << "{ "

          pairs = [] of String

          attributes.each do |key, value|
            pairs << "#{key} = #{value.string}"
          end

          str << pairs.join(", ")
          str << " }"
        end
      end

      def value : ValueType
        dict = {} of String => ValueType

        attributes.each do |key, value|
          dict[key] = value.value
        end

        dict
      end
    end
  end
end
