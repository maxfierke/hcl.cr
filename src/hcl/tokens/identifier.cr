module HCL
  class Token::Identifier < Token
    def value
      string
    end
  end
end
