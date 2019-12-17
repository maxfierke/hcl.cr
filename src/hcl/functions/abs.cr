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

      def call(args : Array(Any)) : Any
        number_arg = args[0]
        number = number_arg.as_i? || number_arg.as_f?

        if !number
          raise ArgumentTypeError.new(
            "abs(number): Argument type mismatch. Expected a number, but got #{number_arg.raw.class}."
          )
        end

        Any.new(number.abs)
      end
    end
  end
end
