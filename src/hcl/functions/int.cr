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
        number_arg = args[0]
        number = number_arg.as_i? || number_arg.as_f?

        if !number
          raise ArgumentTypeError.new(
            "int(number): Argument type mismatch. Expected a number, but got #{number_arg.raw.class}."
          )
        end

        if number < 0_i64
          Any.new(number.ceil)
        else
          Any.new(number.floor)
        end
      end
    end
  end
end
