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

      def call(args : Array(ValueType)) : ValueType
        if args.empty?
          raise FunctionArgumentError.new(
            "max(numbers...): Received empty array. Expected at least one element."
          )
        elsif args.all? { |arg| arg.value.is_a?(Int64) || arg.value.is_a?(Float64) }
          max_val = args.map { |arg| arg.value.as(Int64 | Float64) }.max
          ValueType.new(max_val)
        else
          raise ArgumentTypeError.new(
            "max(numbers...): Argument type mismatch. Expected array of only numbers."
          )
        end
      end
    end
  end
end
