module HCL
  module Functions
    class Lower < Function
      def initialize
        super(
          name: "lower",
          arity: 1,
          varadic: false
        )
      end

      def call(args : Array(ValueType)) : ValueType
        str = args[0].value

        if !str.is_a?(String)
          raise ArgumentTypeError.new(
            "lower(str): Argument type mismatch. Expected a string, but got #{str.class}."
          )
        end

        HCL::ValueType.new(str.downcase)
      end
    end
  end
end
