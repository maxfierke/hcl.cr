module HCL
  module Functions
    class SetHas < Function
      def initialize
        super(
          name: "sethas",
          arity: 2,
          varadic: false
        )
      end

      def call(args : Array(ValueType)) : ValueType
        set_arr = args[0].value
        val = args[1]

        if set_arr.is_a?(Array(ValueType))
          set = set_arr.to_set
          HCL::ValueType.new(set.includes?(val))
        else
          raise ArgumentTypeError.new(
            "sethas(set, val): Argument type mismatch. Expected a set, but got #{set_arr.class}."
          )
        end
      end
    end
  end
end