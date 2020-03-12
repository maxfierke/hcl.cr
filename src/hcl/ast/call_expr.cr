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

      def as_json(ctx : ExpressionContext) : Any
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(to_s)
        else
          evaluate(ctx)
        end
      end
    end
  end
end
