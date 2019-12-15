module HCL
  module Functions
    class Format < Function
      def initialize
        super(
          name: "format",
          arity: 2_u32...ARG_MAX,
          varadic: true
        )
      end

      def call(args : Array(ValueType)) : ValueType
        if !args[0].is_a?(String)
          raise ArgumentTypeError.new(
            "format(fmt, args...): Argument type mismatch. Expected a string, but got #{args[0].class}."
          )
        end

        fmt = args.shift.as(String)

        sprintf(fmt, args)
      end
    end
  end
end
