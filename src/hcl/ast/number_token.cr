module HCL
  module AST
    class NumberToken < ValueToken
      alias Value = Float64 | Int64

      def value
        if string.includes?('.')
          string.to_f64
        else
          string.to_i64
        end
      end
    end
  end
end
