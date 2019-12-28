module HCL
  module AST
    class Map < Node
      getter :attributes

      def initialize(attributes : Hash(String, Node), **kwargs)
        super(**kwargs)

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

      def value(ctx : ExpressionContext) : Any
        dict = {} of String => Any

        attributes.each do |key, value|
          dict[key] = value.value(ctx)
        end

        Any.new(dict)
      end
    end
  end
end
