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
        coll = args[0].raw
        idx = args[1].raw

        if coll.is_a?(Array(Any))
          if !idx.is_a?(Int64)
            raise ArgumentTypeError.new(
              "hasindex(coll, idx): Argument type mismatch. Expected a number, but got #{coll.class}."
            )
          end

          idx = idx.as(Int64)

          HCL::Any.new(!!coll[idx]?)
        elsif coll.is_a?(Hash(String, Any))
          if !idx.is_a?(String)
            raise ArgumentTypeError.new(
              "hasindex(coll, idx): Argument type mismatch. Expected a string, but got #{coll.class}."
            )
          end

          idx = idx.as(String)

          HCL::Any.new(!!coll[idx]?)
        else
          raise ArgumentTypeError.new(
            "hasindex(coll, idx): Argument type mismatch. Expected a collection, but got #{coll.class}."
          )
        end
      end
    end
  end
end
