module HCL
  module AST
    class Literal < Node
      NULL_STR  = "null"
      TRUE_STR  = "true"
      FALSE_STR = "false"

      @literal_type : LiteralType

      private getter :literal_type

      def initialize(source : String = "", token : Pegmatite::Token? = nil, literal_type : LiteralType? = nil)
        super(source, token)
        @literal_type = literal_type || LiteralType::Unknown
      end

      def true?
        !literal_type.string? && source == TRUE_STR
      end

      def false?
        !literal_type.string? && source == FALSE_STR
      end

      def null?
        !literal_type.string? && source == NULL_STR
      end

      def string?
        literal_type.string? || (literal_type.unknown? && ![NULL_STR, TRUE_STR, FALSE_STR].includes?(source))
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
