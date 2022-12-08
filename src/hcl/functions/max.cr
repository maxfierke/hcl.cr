module HCL
  module Functions
    class Max < Function
      def initialize
        super(
          name: "max",
          arity: 1_u32...ARG_MAX,
          varadic: true
        )
      end

      def call(args : Array(Any)) : Any
        if args.empty?
          raise FunctionArgumentError.new(
            "max(numbers...): Received empty array. Expected at least one element."
          )
        else
          max_val = args.map { |arg|
            arg.as_i? || arg.as_f? || arg.as_big_d? || raise ArgumentTypeError.new(
              "max(numbers...): Argument type mismatch. Expected array of only numbers."
            )
          }.max
          Any.new(max_val)
        end
      end
    end
  end
end
