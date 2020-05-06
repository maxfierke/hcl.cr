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

      def block_header(ctx : ExpressionContext)
        Array(Any).new(labels.size + 1).tap do |arr|
          arr << Any.new(id)
          labels.each do |label|
            arr << label.value(ctx)
          end

          arr
        end
      end

      def value(ctx : ExpressionContext) : Any
        block_value = super(ctx)
        block_header(ctx).reverse.reduce(block_value) do |acc, val|
          Any.new({val.to_s => acc})
        end
      end
    end
  end
end
