module HCL
  class Token::List < ValueToken
    getter :children

    def initialize(peg_tuple : Pegmatite::Token, string : ::String)
      super(peg_tuple, string)
      @children = [] of HCL::ValueToken
    end

    def <<(token : HCL::ValueToken)
      @children << token
    end

    def value
      children.map do |item|
        item.value.as(HCL::ValueType)
      end
    end
  end
end
