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

      def call(args : Array(ValueType)) : ValueType
        val = args[0]
        val.to_json
      end
    end
  end
end
