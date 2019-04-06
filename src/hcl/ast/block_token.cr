module HCL
  module AST
    class BlockToken < Token
      getter :id, :args, :values, :blocks

      alias Value = NamedTuple(
        id: String,
        args: Array(String),
        values: Hash(String, ValueType),
        blocks: Array(Value)
      )

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

      def value
        {
          id: id,
          args: args.map { |arg| arg.value.as(String) },
          values: values_dict,
          blocks: blocks.map { |block| block.value.as(Value) }
        }
      end

      private def values_dict
        dict = {} of String => ValueType

        values.each do |key, value|
          dict[key] = value.value.as(ValueType)
        end

        dict
      end
    end
  end
end
