module HCL
  module Functions
    class Int < Function
      def initialize
        super(
          name: "int",
          arity: 1,
          varadic: false
        )
      end

      def call(args : Array(Any)) : Any
        number = args[0].raw

        if !number.is_a?(Int64) && !number.is_a?(Float64)
          raise ArgumentTypeError.new(
            "int(number): Argument type mismatch. Expected a number, but got #{number.class}."
          )
        end

        number = number.as(Int64 | Float64)

        if number < 0_i64
          Any.new(number.ceil)
        else
          Any.new(number.floor)
        end
      end
    end
  end
end
