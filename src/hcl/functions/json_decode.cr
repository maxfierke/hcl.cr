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

      def call(args : Array(Any)) : Any
        str = args[0].raw

        if !str.is_a?(String)
          raise ArgumentTypeError.new(
            "jsonencode(str): Argument type mismatch. Expected a string, but got #{str.class}."
          )
        end

        HCL::Any.from_json(str)
      end
    end
  end
end
