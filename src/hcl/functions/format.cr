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

      def call(args : Array(Any)) : Any
        if !args[0].as_s?
          raise ArgumentTypeError.new(
            "format(fmt, args...): Argument type mismatch. Expected a string, but got #{args[0].raw.class}."
          )
        end

        fmt = args.shift.as_s

        Any.new(sprintf(fmt, args.map(&.unwrap)))
      end
    end
  end
end
