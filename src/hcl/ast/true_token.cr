module HCL
  module AST
    class TrueToken < ValueToken
      STRING_VAL = "true"

      def initialize(peg_tuple : Pegmatite::Token)
        super(peg_tuple, STRING_VAL)
      end

      def string
        STRING_VAL
      end

      def value
        true
      end
    end
  end
end
