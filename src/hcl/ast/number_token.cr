module HCL
  module AST
    class NumberToken < ValueToken
      alias Value = Float64 | Int64

      def initialize(peg_tuple : Pegmatite::Token, string : String)
        stripped_string = string.strip('"')
        super(peg_tuple, stripped_string)
      end

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
