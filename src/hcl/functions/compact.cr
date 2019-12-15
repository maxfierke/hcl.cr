module HCL
  module Functions
    class Compact < Function
      def initialize
        super(
          name: "compact",
          arity: 1_u32...ARG_MAX,
          varadic: true
        )
      end

      def call(args : Array(ValueType)) : ValueType
        result = args.select { |arg| !arg.value.nil? }
        HCL::ValueType.new(result)
      end
    end
  end
end
