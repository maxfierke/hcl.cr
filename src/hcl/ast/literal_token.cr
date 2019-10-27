module HCL
  module AST
    class LiteralToken < ValueToken
      @value : Nil | Bool

      NULL_STR = "null"
      TRUE_STR = "true"
      FALSE_STR = "false"

      def string
        if value == true
          TRUE_STR
        elsif value == false
          FALSE_STR
        else
          NULL_STR
        end
      end

      def value : ValueType
        @value ||= if source == NULL_STR
          nil
        elsif source == TRUE_STR
          true
        elsif source == FALSE_STR
          false
        else
          raise "BUG: Unexpected literal value"
        end
      end
    end
  end
end
