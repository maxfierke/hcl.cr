module HCL
  module AST
    class BlockToken < Token
      getter :id, :labels, :attributes, :blocks

      # :nodoc:
      # This whole override should be unnecessary, but for some reason
      # parser.cr's build_block isn't typing the array properly, so we're
      # casting it here.
      def initialize(
        peg_tuple : Pegmatite::Token,
        string : String,
        id : String,
        labels : Array(Token),
        attributes : Hash(String, Token),
        blocks : Array(BlockToken)
      )
        block_labels = labels.map! do |arg|
          if arg.is_a?(AST::StringToken)
            arg.as(AST::StringToken)
          elsif arg.is_a?(AST::IdentifierToken)
            arg.as(AST::IdentifierToken)
          else
            raise "PARSER BUG"
          end
        end

        super(peg_tuple, string)

        @id = id
        @labels = block_labels
        @attributes = attributes
        @blocks = blocks
      end

      def initialize(
        peg_tuple : Pegmatite::Token,
        string : String,
        id : String,
        labels : Array(StringToken | IdentifierToken),
        attributes : Hash(String, Token),
        blocks : Array(BlockToken)
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

      def value : ValueType
        block_header = [id] + labels.map(&.value)
        block_value = value_dict.as(ValueType)
        block_header.reverse.reduce(block_value) do |acc, val|
          { val.to_s => acc.as(ValueType) }
        end.as(Hash(String, ValueType)).as(ValueType)
      end

      private def value_dict
        dict = {} of String => ValueType

        attributes.each do |key, value|
          dict[key] = value.value.as(ValueType)
        end

        blocks.each do |block|
          block_dict = block.value.as(Hash(String, ValueType))
          dict.merge!(block_dict)
        end

        dict
      end
    end
  end
end
