module HCL
  module Functions
    class Length < Function
      def initialize
        super(
          name: "length",
          arity: 1,
          varadic: false
        )
      end

      def call(args : Array(Any)) : Any
        coll_arg = args[0]
        coll = coll_arg.as_a? || coll_arg.as_h?

        if !coll
          raise ArgumentTypeError.new(
            "length(coll): Argument type mismatch. Expected a collection, but got #{coll_arg.raw.class}."
          )
        end

        Any.new(coll.size.to_i64)
      end
    end
  end
end
