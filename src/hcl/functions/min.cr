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
        elsif args.all? { |arg| arg.raw.is_a?(Int64) || arg.raw.is_a?(Float64) }
          min_val = args.map { |arg| arg.raw.as(Int64 | Float64) }.min
          Any.new(min_val)
        else
          raise ArgumentTypeError.new(
            "min(numbers...): Argument type mismatch. Expected array of only numbers."
          )
        end
      end
    end
  end
end
