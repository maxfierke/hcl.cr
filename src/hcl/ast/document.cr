module HCL
  module AST
    class Document < Node
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

      def string : String
        String.build do |str|
          attributes.each do |key, value|
            str << "#{key} = #{value.string}\n"
          end

          blocks.each do |block|
            block_lines = block.string.split("\n")
            block_lines.each do |line|
              str << "#{line}\n"
            end
          end
        end
      end

      def value
        value(ExpressionContext.new)
      end

      def value(ctx : ExpressionContext) : ValueType
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
