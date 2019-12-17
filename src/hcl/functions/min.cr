module HCL
  module Functions
    class Min < Function
      def initialize
        super(
          name: "min",
          arity: 1_u32...ARG_MAX,
          varadic: true
        )
      end

      def call(args : Array(Any)) : Any
        if args.empty?
          raise FunctionArgumentError.new(
            "min(numbers...): Received empty array. Expected at least one element."
          )
        else
          min_val = args.map { |arg|
            arg.as_i? || arg.as_f? || raise ArgumentTypeError.new(
              "min(numbers...): Argument type mismatch. Expected array of only numbers."
            )
          }.min
          Any.new(min_val)
        end
      end
    end
  end
end
