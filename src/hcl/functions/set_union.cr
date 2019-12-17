module HCL
  module Functions
    class SetUnion < Function
      def initialize
        super(
          name: "setunion",
          arity: 2_u32...ARG_MAX,
          varadic: true
        )
      end

      def call(args : Array(Any)) : Any
        initial_arg = args.first.raw
        initial_arg = assert_array!(initial_arg)
        initial = initial_arg.to_set

        result = args.reduce(initial) do |acc, el|
          val = el.raw
          val = assert_array!(val)

          acc | val.to_set
        end

        Any.new(result.to_a)
      end

      private def assert_array!(value)
        if value.is_a?(Array(Any))
          value
        else
          raise ArgumentTypeError.new(
            "setunion(sets...): Argument type mismatch. Expected an array, but got #{value.class}."
          )
        end
      end
    end
  end
end
