module HCL
  module AST
    class Literal < Node
      NULL_STR  = "null"
      TRUE_STR  = "true"
      FALSE_STR = "false"

      def value(ctx : ExpressionContext) : Any
        if source == TRUE_STR
          Any.new(true)
        elsif source == FALSE_STR
          Any.new(false)
        elsif source == NULL_STR
          Any.new(nil)
        else
          Any.new(source)
        end
      end

      def string?
        ![NULL_STR, TRUE_STR, FALSE_STR].includes?(source)
      end
    end
  end
end
