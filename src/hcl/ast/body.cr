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

      def as_json(ctx : ExpressionContext) : Any
        dict = {} of String => Any

        attributes.each do |key, value|
          dict[key] = value.as_json(ctx)
        end

        blocks.each do |block|
          block_dict = block.as_json(ctx).as_h
          deep_merge_blocks!(dict, block_dict)
        end

        Any.new(dict)
      end
    end
  end
end
