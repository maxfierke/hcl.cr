module HCL
  module AST
    class Body < Node
      getter :attributes, :blocks

      def initialize(
        peg_tuple : Pegmatite::Token,
        string : String,
        attributes : Hash(String, Node),
        blocks : Array(Block)
      )
        super(peg_tuple, string)

        @attributes = attributes
        @blocks = blocks
      end

      def to_s(io : IO)
        attributes.each do |key, value|
          io << key
          io << " = "
          value.to_s(io)
          io << "\n"
        end

        io << "\n" if attributes.any?

        blocks.each do |block|
          block.to_s(io)
          io << "\n"
        end
      end

      def value(ctx : ExpressionContext) : Any
        dict = {} of String => Any

        attributes.each do |key, value|
          dict[key] = value.value(ctx)
        end

        blocks.each do |block|
          block_dict = block.value(ctx).as_h
          dict.merge!(block_dict)
        end

        Any.new(dict)
      end
    end
  end
end
