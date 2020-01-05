module HCL
  module AST
    class Number < Node
      alias Value = Float64 | Int64

      @value : Value

      def initialize(source, token : Pegmatite::Token? = nil)
        super(source: source.strip('"'), token: token)

        @value = if @source.includes?('.')
                   @source.to_f64
                 else
                   @source.to_i64
                 end
      end

      def initialize(number : Value, **kwargs)
        super(**kwargs)
        @source = number.to_s
        @value = number
      end

      def to_s(io : IO)
        @value.to_s(io)
      end

      def value(ctx : ExpressionContext) : Any
        Any.new(@value)
      end
    end
  end
end
