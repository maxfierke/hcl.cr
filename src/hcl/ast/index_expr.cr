module HCL
  module AST
    class IndexExpr < Node
      getter :index_exp

      def initialize(index_exp : Expression, **kwargs)
        super(**kwargs)
        @index_exp = index_exp
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
