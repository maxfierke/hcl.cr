module HCL
  module AST
    class Block < Node
      @labels : Array(BlockLabel)

      getter :id, :labels, :attributes, :blocks

      def initialize(
        peg_tuple : Pegmatite::Token,
        string : String,
        id : String,
        labels : Array(BlockLabel),
        attributes : Hash(String, Node),
        blocks : Array(Block)
      )
        super(peg_tuple, string)

        @id = id
        @labels = labels
        @attributes = attributes
        @blocks = blocks
      end

      def string : String
        String.build do |str|
          str << "#{id} #{labels.map(&.string).join(" ")} {\n"

          attributes.each do |key, value|
            str << "  #{key} = #{value.string}\n"
          end

          blocks.each do |block|
            block_lines = block.string.split("\n")
            block_lines.each do |line|
              str << "  #{line}\n"
            end
          end

          str << "}\n"
        end
      end

      def value(ctx : ExpressionContext) : ValueType
        block_header = [id] + labels.map do |label|
          label.value(ctx)
        end
        block_value = value_dict(ctx).as(ValueType)
        block_header.reverse.reduce(block_value) do |acc, val|
          { val.to_s => acc.as(ValueType) }
        end.as(Hash(String, ValueType)).as(ValueType)
      end

      private def value_dict(ctx)
        dict = {} of String => ValueType

        attributes.each do |key, value|
          dict[key] = value.value(ctx).as(ValueType)
        end

        blocks.each do |block|
          block_dict = block.value(ctx).as(Hash(String, ValueType))
          dict.merge!(block_dict)
        end

        dict
      end
    end
  end
end
