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
        "#{id}(#{args.map(&.string).join(", ")})"
      end

      def value(ctx : ExpressionContext) : ValueType
        call_args = args.map do |arg|
          arg.value(ctx)
        end

        ctx.call_func(id, call_args)
      end
    end
  end
end
