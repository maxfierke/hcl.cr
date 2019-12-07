module HCL
  module AST
    class CallExpr < Node
      getter :id, :args
      getter? :varadic

      def initialize(
        peg_tuple : Pegmatite::Token,
        string : String,
        id : String,
        args : Array(Node),
        varadic : Bool
      )
        super(peg_tuple, string)

        @id = id
        @args = args
        @varadic = varadic
      end

      def to_s(io : IO)
        io << id
        io << "("

        args.each_with_index do |arg, index|
          arg.to_s(io)

          if varadic? && index == (args.size - 1) && arg.is_a?(Identifier)
            io << "..."
          end
        end

        io << ")"
      end

      def value(ctx : ExpressionContext) : ValueType
        call_args = evaluate_args(ctx)
        ctx.call_func(id, call_args)
      end

      private def evaluate_args(ctx)
        call_args = args.map { |arg| arg.value(ctx) }

        if varadic?
          varadic_args = call_args.pop

          if !varadic_args.is_a?(Array(ValueType))
            raise "Expected varadic argument to evaluate to a list"
          end

          varadic_args.each { |arg| call_args << arg }
        end

        call_args
      end
    end
  end
end
