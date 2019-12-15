module HCL
  module AST
    class Number < Node
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

      def to_s(io : IO)
        @value.to_s(io)
      end

      def value(ctx : ExpressionContext) : ValueType
        ValueType.new(@value)
      end
    end
  end
end
