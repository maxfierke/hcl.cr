module HCL
  module AST
    abstract class Body < Node
      getter :attributes, :blocks

      def initialize(
        attributes : Hash(String, Node) = Hash(String, Node).new,
        blocks : Array(Block) = Array(Block).new,
        **kwargs
      )
        super(**kwargs)

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
          io << "\n" unless blocks.last == block
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
