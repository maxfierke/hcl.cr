module HCL
  module AST
    class NumberToken < ValueToken
      alias Value = Float64 | Int64

      @value : Value

      getter :value

      def initialize(peg_tuple : Pegmatite::Token, string : String)
        stripped_string = string.strip('"')
        super(peg_tuple, stripped_string)

        @value = if source.includes?('.')
          source.to_f64
        else
          source.to_i64
        end
      end

      def string
        value.to_s
      end
    end
  end
end
