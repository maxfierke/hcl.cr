module HCL
  module AST
    class Number < Node
      alias Value = Float64 | Int64

      @value : Value

      getter :value

      def initialize(source : String, token : Pegmatite::Token? = nil)
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

      def as_json(ctx : ExpressionContext) : Any
        evaluate(ctx)
      end
    end
  end
end
