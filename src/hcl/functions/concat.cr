module HCL
  module Functions
    class Concat < Function
      def initialize
        super(
          name: "concat",
          arity: 1_u32...ARG_MAX,
          varadic: true
        )
      end

      def call(args : Array(ValueType)) : ValueType
        arr = Array(ValueType).new

        args.reduce(arr) do |acc, val|
          if val.is_a?(Array(ValueType))
            acc.concat(val)
          else
            raise ArgumentTypeError.new(
              "concat(seqs...): Argument type mismatch. Expected an array, but got #{val.class}."
            )
          end
        end
      end
    end
  end
end
