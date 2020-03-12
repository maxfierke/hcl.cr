module HCL
  module AST
    class SplatExpr < Node
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
