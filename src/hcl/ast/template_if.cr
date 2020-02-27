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

      def to_s(io : IO)
        io << "%{if "
        predicate.to_s(io)
        io << "}"
        true_tpl.to_s(io)

        if fals_tpl = false_tpl
          io << "%{else}"
          fals_tpl.to_s(io)
        end

        io << "%{endif}"
      end

      def value(ctx : ExpressionContext) : Any
        predicate_value = predicate.value(ctx).raw

        # TODO: validate "correctness" of both expressions to catch errors in
        # HCL construction, if even not for the active path

        if truthy?(predicate_value)
          true_tpl.value(ctx)
        elsif fals_tpl = false_tpl
          fals_tpl.value(ctx)
        else
          Any.new("")
        end
      end

      # TODO: Verify these invariants
      private def truthy?(val : Int64)
        val != 0
      end

      private def truthy?(val : String)
        val != ""
      end

      private def truthy?(val)
        !!val
      end
    end
  end
end
