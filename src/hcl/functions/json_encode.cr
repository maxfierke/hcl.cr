module HCL
  module Functions
    class JSONEncode < Function
      def initialize
        super(
          name: "jsonencode",
          arity: 1,
          varadic: false
        )
      end

      def call(args : Array(Any)) : Any
        val = args[0]
        Any.new(val.to_json)
      end
    end
  end
end
