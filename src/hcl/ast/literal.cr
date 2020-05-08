module HCL
  module AST
    class Literal < Node
      NULL_STR  = "null"
      TRUE_STR  = "true"
      FALSE_STR = "false"

      def true?
        source == TRUE_STR
      end

      def false?
        source == FALSE_STR
      end

      def null?
        source == NULL_STR
      end

      def string?
        ![NULL_STR, TRUE_STR, FALSE_STR].includes?(source)
      end

      def value
        if true?
          true
        elsif false?
          false
        elsif null?
          nil
        else
          source
        end
      end
    end
  end
end
