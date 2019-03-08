module HCL
  class Token::Number < Token
    @value : Float64? | Int64?

    def value
      @value ||= if string.includes?('.')
        string.to_f64
      else
        string.to_i64
      end
    end
  end
end
