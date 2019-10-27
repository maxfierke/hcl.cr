module HCL
  module AST
    class BlockToken < Token
      getter :id, :args, :values, :blocks

      # :nodoc:
      # This whole override should be unnecessary, but for some reason
      # parser.cr's build_block isn't typing the array properly, so we're
      # casting it here.
      def initialize(
        peg_tuple : Pegmatite::Token,
        string : String,
        id : String,
        args : Array(ValueToken),
        values : Hash(String, ValueToken),
        blocks : Array(BlockToken)
      )
        block_args = args.map! do |arg|
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
        @args = block_args
        @values = values
        @blocks = blocks
      end

      def initialize(
        peg_tuple : Pegmatite::Token,
        string : String,
        id : String,
        args : Array(StringToken | IdentifierToken),
        values : Hash(String, ValueToken),
        blocks : Array(BlockToken)
      )
        super(peg_tuple, string)

        @id = id
        @args = args
        @values = values
        @blocks = blocks
      end

      def string
        String.build do |str|
          str << "#{id} #{args.map(&.string).join(" ")} {\n"

          values.each do |key, value|
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
        block_header = [id] + args.map(&.value)
        block_value = value_dict.as(ValueType)
        block_header.reverse.reduce(block_value) do |acc, val|
          { val.to_s => acc.as(ValueType) }
        end.as(Hash(String, ValueType)).as(ValueType)
      end

      private def value_dict
        dict = {} of String => ValueType

        values.each do |key, value|
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
