module HCL
  module AST
    class TemplateIf < Node
      getter :predicate, :true_tpl, :false_tpl

      def initialize(
        predicate : Expression,
        true_tpl : Template,
        false_tpl : Template? = nil,
        **kwargs,
      )
        super(**kwargs)
        @predicate = predicate
        @true_tpl = true_tpl
        @false_tpl = false_tpl
      end
    end
  end
end
