module HCL
  module AST
    class CallToken < ValueToken
      getter :id, :args

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

      def string
        "#{id}(#{args.map(&.value).join(", ")})"
      end

      def value : ValueType
        # This is wrong, but haven't implemented function
        # call evaluation yet.
        nil
      end
    end
  end
end
