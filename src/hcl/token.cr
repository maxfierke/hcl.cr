module HCL
  abstract class Token
    @kind : Symbol

    getter :string, :kind

    def initialize(peg_tuple : Pegmatite::Token, string : ::String)
      kind, src_start, src_finish = peg_tuple
      @kind = kind
      @string = string
    end

    def as_s
      string
    end

    abstract def value
  end

  alias SimpleType = Nil | Bool | Int64 | Float64 | ::String | Array(SimpleType)
  alias SimpleToken =
    Token::False |
    Token::True |
    Token::String |
    Token::Number |
    Token::Null |
    Token::List
end
