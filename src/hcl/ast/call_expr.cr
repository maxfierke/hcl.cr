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

      def string : String
        String.build do |str|
          str << id
          str << "("

          args.each_with_index do |arg, index|
            str << arg.string

            if varadic? && index == (args.size - 1) && arg.is_a?(Identifier)
              str << "..."
            end
          end

          str << ")"
        end
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
