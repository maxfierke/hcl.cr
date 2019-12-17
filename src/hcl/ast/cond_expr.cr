module HCL
  module AST
    class CondExpr < Node
      getter :predicate, :true_expr, :false_expr

      def initialize(
        peg_tuple : Pegmatite::Token,
        string : String,
        predicate : Expression,
        true_expr : Expression,
        false_expr : Expression
      )
        super(peg_tuple, string)
        @predicate = predicate
        @true_expr = true_expr
        @false_expr = false_expr
      end

      def to_s(io : IO)
        predicate.to_s(io)
        io << " ? "
        true_expr.to_s(io)
        io << " : "
        false_expr.to_s(io)
      end

      def value(ctx : ExpressionContext) : ValueType
        predicate_value = predicate.value(ctx).raw

        # TODO: validate "correctness" of both expressions to catch errors in
        # HCL construction, if even not for the active path

        if truthy?(predicate_value)
          true_expr.value(ctx)
        else
          false_expr.value(ctx)
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
