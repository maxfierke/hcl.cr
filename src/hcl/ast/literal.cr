module HCL
  module AST
    class Literal < Node
      @value : Nil | Bool

      NULL_STR = "null"
      TRUE_STR = "true"
      FALSE_STR = "false"

      def string : String
        if value == true
          TRUE_STR
        elsif value == false
          FALSE_STR
        else
          NULL_STR
        end
      end

      def value : ValueType
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
