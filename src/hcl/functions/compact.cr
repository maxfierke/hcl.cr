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

      def call(args : Array(Any)) : Any
        result = args.select { |arg| !arg.raw.nil? }
        HCL::Any.new(result)
      end
    end
  end
end
