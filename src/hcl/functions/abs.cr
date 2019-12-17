module HCL
  module Functions
    class Abs < Function
      def initialize
        super(
          name: "abs",
          arity: 1,
          varadic: false
        )
      end

      def call(args : Array(ValueType)) : ValueType
        number = args[0].raw

        if !number.is_a?(Int64) && !number.is_a?(Float64)
          raise ArgumentTypeError.new(
            "abs(number): Argument type mismatch. Expected a number, but got #{number.class}."
          )
        end

        result = number.as(Int64 | Float64).abs

        ValueType.new(result)
      end
    end
  end
end
