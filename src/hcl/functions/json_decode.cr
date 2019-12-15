module HCL
  module Functions
    class JSONDecode < Function
      def initialize
        super(
          name: "jsondecode",
          arity: 1,
          varadic: false
        )
      end

      def call(args : Array(ValueType)) : ValueType
        str = args[0]

        if !str.is_a?(String)
          raise ArgumentTypeError.new(
            "jsonencode(str): Argument type mismatch. Expected a string, but got #{str.class}."
          )
        end

        json = JSON.parse(str)
        json.raw.as(ValueType)
      end
    end
  end
end
