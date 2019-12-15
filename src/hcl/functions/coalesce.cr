module HCL
  module Functions
    class Coalesce < Function
      def initialize
        super(
          name: "coalesce",
          arity: 1_u32...ARG_MAX,
          varadic: true
        )
      end

      def call(args : Array(ValueType)) : ValueType
        val = args.find { |arg| !arg.nil? }

        val
      end
    end
  end
end
