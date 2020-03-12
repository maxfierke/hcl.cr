module HCL
  module AST
    class TemplateIf < Node
      getter :predicate, :true_tpl, :false_tpl

      def initialize(
        predicate : Expression,
        true_tpl : Template,
        false_tpl : Template? = nil,
        **kwargs
      )
        super(**kwargs)
        @predicate = predicate
        @true_tpl = true_tpl
        @false_tpl = false_tpl
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
