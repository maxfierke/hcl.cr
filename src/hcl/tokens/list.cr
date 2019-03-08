module HCL
  class Token::List < Token
    getter :children

    def initialize(peg_tuple : Pegmatite::Token, string : ::String)
      super(peg_tuple, string)
      @children = [] of HCL::SimpleToken
    end

    def <<(token)
      @children << token
    end

    def value
      @children.map do |item|
        if item.is_a?(HCL::SimpleToken)
          item.value.as(HCL::SimpleType)
        else
          raise "BUG: List has child that is not listable."
        end
      end
    end
  end
end
