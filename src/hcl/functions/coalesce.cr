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

      def call(args : Array(Any)) : Any
        val = args.find { |arg| !arg.raw.nil? }

        val ? val : Any.new(nil)
      end
    end
  end
end
