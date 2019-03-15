module HCL
  class Token::Number < ValueToken
    alias Value = Nil | Float64 | Int64
    @value : Value

    def value
      @value ||= if string.includes?('.')
        string.to_f64
      else
        string.to_i64
      end
    end
  end
end
