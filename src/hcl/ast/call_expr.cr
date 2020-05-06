module HCL
  module AST
    class CallExpr < Node
      getter :id, :args
      getter? :varadic

      def initialize(
        id : String,
        args : Array(Node),
        varadic : Bool,
        **kwargs
      )
        super(**kwargs)

        @id = id
        @args = args
        @varadic = varadic
      end

      def value(ctx : ExpressionContext) : Any
        call_args = evaluate_args(ctx)
        ctx.call_func(id, call_args)
      end

      private def evaluate_args(ctx)
        call_args = args.map { |arg| arg.value(ctx) }

        if varadic?
          varadic_args = call_args.pop.raw

          if !varadic_args.is_a?(Array(Any))
            raise "Expected varadic argument to evaluate to a list"
          end

          varadic_args.map(&.raw).each { |arg| call_args << HCL::Any.new(arg) }
        end

        call_args
      end
    end
  end
end
