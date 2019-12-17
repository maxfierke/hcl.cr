module HCL
  module Functions
    class Strlen < Function
      def initialize
        super(
          name: "strlen",
          arity: 1,
          varadic: false
        )
      end

      def call(args : Array(Any)) : Any
        str = args[0].raw

        if !str.is_a?(String)
          raise ArgumentTypeError.new(
            "strlen(str): Argument type mismatch. Expected a string, but got #{str.class}."
          )
        end

        HCL::Any.new(str.size.to_i64)
      end
    end
  end
end
