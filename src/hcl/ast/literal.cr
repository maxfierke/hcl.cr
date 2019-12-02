module HCL
  module AST
    class Literal < Node
      @value : Nil | Bool

      NULL_STR = "null"
      TRUE_STR = "true"
      FALSE_STR = "false"

      def string : String
        source
      end

      def value(ctx : ExpressionContext) : ValueType
        @value ||= if source == TRUE_STR
          true
        elsif source == FALSE_STR
          false
        else
          nil
        end
      end
    end
  end
end
