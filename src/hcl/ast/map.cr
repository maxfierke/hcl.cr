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

      def to_s(io : IO)
        io << "{ "

        pairs = [] of String

        attributes.each do |key, value|
          pairs << "#{key} = #{value.to_s}"
        end

        io << pairs.join(", ")
        io << " }"
      end

      def value(ctx : ExpressionContext) : ValueType
        dict = {} of String => ValueType

        attributes.each do |key, value|
          dict[key] = value.value(ctx)
        end

        ValueType.new(dict)
      end
    end
  end
end
