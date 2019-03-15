module HCL
  module AST
    class CallToken < ValueToken
      getter :id, :args

      alias Value = NamedTuple(
        id: String,
        args: Array(ValueType)
      )

      def initialize(
        peg_tuple : Pegmatite::Token,
        string : String,
        id : String,
        args : Array(ValueToken),
      )
        super(peg_tuple, string)

        @id = id
        @args = args
      end

      def value
        {
          id: id,
          args: args.map { |arg| arg.value.as(ValueType) },
        }
      end
    end
  end
end
