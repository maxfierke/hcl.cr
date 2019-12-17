module HCL
  module Functions
    class HasIndex < Function
      def initialize
        super(
          name: "hasindex",
          arity: 2,
          varadic: false
        )
      end

      def call(args : Array(Any)) : Any
        coll = args[0]
        idx_or_key = args[1]

        if arr = coll.as_a?
          if idx = idx_or_key.as_i?
            HCL::Any.new(!!arr[idx]?)
          else
            raise ArgumentTypeError.new(
              "hasindex(coll, idx): Argument type mismatch. Expected a number, but got #{coll.raw.class}."
            )
          end
        elsif hsh = coll.as_h?
          if key = idx_or_key.as_s?
            HCL::Any.new(!!hsh[key]?)
          else
            raise ArgumentTypeError.new(
              "hasindex(coll, idx): Argument type mismatch. Expected a string, but got #{coll.raw.class}."
            )
          end
        else
          raise ArgumentTypeError.new(
            "hasindex(coll, idx): Argument type mismatch. Expected a collection, but got #{coll.raw.class}."
          )
        end
      end
    end
  end
end
