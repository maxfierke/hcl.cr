module HCL
  module AST
    class CallExpr < Node
      getter :id, :args

      def initialize(
        peg_tuple : Pegmatite::Token,
        string : String,
        id : String,
        args : Array(Node),
      )
        super(peg_tuple, string)

        @id = id
        @args = args
      end

      def string : String
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
