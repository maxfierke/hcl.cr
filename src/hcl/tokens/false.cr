module HCL
  class Token::False < Token
    STRING_VAL = "false"

    def initialize(peg_tuple : Pegmatite::Token)
      super(peg_tuple, STRING_VAL)
    end

    def string
      STRING_VAL
    end

    def value
      false
    end
  end
end
