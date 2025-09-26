module HCL
  module AST
    class CondExpr < Node
      getter :predicate, :true_expr, :false_expr

      def initialize(
        predicate : Expression,
        true_expr : Expression,
        false_expr : Expression,
        **kwargs,
      )
        super(**kwargs)
        @predicate = predicate
        @true_expr = true_expr
        @false_expr = false_expr
      end
    end
  end
end
