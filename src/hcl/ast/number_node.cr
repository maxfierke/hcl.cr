module HCL
  module AST
    class NumberNode < Node
      alias Value = Float64 | Int64

      @value : Value

      def initialize(peg_tuple : Pegmatite::Token, string : String)
        stripped_string = string.strip('"')
        super(peg_tuple, stripped_string)

        @value = if source.includes?('.')
          source.to_f64
        else
          source.to_i64
        end
      end

      def string : String
        value.to_s
      end

      def value : ValueType
        @value
      end
    end
  end
end
