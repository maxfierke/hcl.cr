module HCL
  module AST
    class Number < Node
      alias Value = BigDecimal | Float64 | Int64

      @value : Value

      getter :value

      def initialize(source : String, token : Pegmatite::Token? = nil)
        super(source: source.strip('"'), token: token)

        @value =
          if @source.includes?('.')
            if @source.gsub(/[^\d]+/, "").size > Float64::DIGITS
              @source.to_big_d
            else
              @source.to_f64
            end
          else
            if @source.size >= 19
              @source.to_big_d
            else
              @source.to_i64
            end
          end
      end

      def initialize(number : Value, **kwargs)
        super(**kwargs)
        @source = number.to_s
        @value = number
      end
    end
  end
end
