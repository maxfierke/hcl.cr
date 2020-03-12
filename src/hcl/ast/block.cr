module HCL
  module AST
    class Block < Body
      @labels : Array(BlockLabel)

      getter :id, :labels

      def initialize(
        id : String,
        labels : Array(BlockLabel) = Array(BlockLabel).new,
        attributes : Hash(String, Node) = Hash(String, Node).new,
        blocks : Array(Block) = Array(Block).new,
        **kwargs
      )
        super(attributes, blocks, **kwargs)

        @id = id
        @labels = labels
      end

      def as_json(ctx : ExpressionContext) : Any
        block_value = super(ctx)
        block_header(ctx).reverse.reduce(block_value) do |acc, val|
          Any.new({val => acc})
        end
      end
    end
  end
end
