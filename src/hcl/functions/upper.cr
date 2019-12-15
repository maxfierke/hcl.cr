module HCL
  module Functions
    class Upper < Function
      def initialize
        super(
          name: "upper",
          arity: 1,
          varadic: false
        )
      end

      def call(args : Array(ValueType)) : ValueType
        str = args[0].value

        if !str.is_a?(String)
          raise ArgumentTypeError.new(
            "upper(str): Argument type mismatch. Expected a string, but got #{str.class}."
          )
        end

        HCL::ValueType.new(str.upcase)
      end
    end
  end
end
