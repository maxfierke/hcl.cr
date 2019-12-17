module HCL
  module Functions
    class SetIntersection < Function
      def initialize
        super(
          name: "setintersection",
          arity: 2_u32...ARG_MAX,
          varadic: true
        )
      end

      def call(args : Array(ValueType)) : ValueType
        initial_arg = args.first.raw
        initial_arg = assert_array!(initial_arg)
        initial = initial_arg.to_set

        result = args.reduce(initial) do |acc, el|
          val = el.raw
          val = assert_array!(val)

          acc & val.to_set
        end

        ValueType.new(result.to_a)
      end

      private def assert_array!(value)
        if value.is_a?(Array(ValueType))
          value
        else
          raise ArgumentTypeError.new(
            "setintersection(sets...): Argument type mismatch. Expected an array, but got #{value.class}."
          )
        end
      end
    end
  end
end
