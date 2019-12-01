module HCL
  module AST
    class ConditionalNode < Node
      getter :predicate, :true_expr, :false_expr

      def initialize(
        peg_tuple : Pegmatite::Token,
        string : String,
        predicate : ExpressionNode,
        true_expr : ExpressionNode,
        false_expr : ExpressionNode
      )
        super(peg_tuple, string)
        @predicate = predicate
        @true_expr = true_expr
        @false_expr = false_expr
      end

      def string : String
        "#{predicate.string} ? #{true_expr.string} : #{false_expr.string}"
      end

      def value : ValueType
        predicate_value = predicate.value

        if truthy?(predicate_value)
          true_expr.value
        else
          false_expr.value
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
