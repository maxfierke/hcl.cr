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
        args.select { |arg| !arg.nil? }.map { |arg| arg.as(ValueType) }
      end
    end
  end
end
