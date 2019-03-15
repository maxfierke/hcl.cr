module HCL
  class Token::Null < ValueToken
    STRING_VAL = "null"

    def initialize(peg_tuple : Pegmatite::Token)
      super(peg_tuple, STRING_VAL)
    end

    def string
      STRING_VAL
    end

    def value
      nil
    end
  end
end
