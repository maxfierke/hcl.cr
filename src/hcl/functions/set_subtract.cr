module HCL
  module Functions
    class SetSubtract < Function
      def initialize
        super(
          name: "setsubtract",
          arity: 2,
          varadic: true
        )
      end

      def call(args : Array(ValueType)) : ValueType
        arg1 = args.shift.raw
        arg1 = assert_array!(arg1)

        arg2 = args.shift.raw
        arg2 = assert_array!(arg2)

        result = arg1.to_set - arg2.to_set

        ValueType.new(result.to_a)
      end

      private def assert_array!(value)
        if value.is_a?(Array(ValueType))
          value
        else
          raise ArgumentTypeError.new(
            "setsubtract(set1, set2): Argument type mismatch. Expected an array, but got #{value.class}."
          )
        end
      end
    end
  end
end
