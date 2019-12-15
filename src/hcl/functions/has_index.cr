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

      def call(args : Array(ValueType)) : ValueType
        coll = args[0]
        idx = args[1]

        if coll.is_a?(Array(ValueType))
          if !idx.is_a?(Int64)
            raise ArgumentTypeError.new(
              "hasindex(coll, idx): Argument type mismatch. Expected a number, but got #{coll.class}."
            )
          end

          idx = idx.as(Int64)

          !!coll[idx]?
        elsif coll.is_a?(Hash(String, ValueType))
          if !idx.is_a?(String)
            raise ArgumentTypeError.new(
              "hasindex(coll, idx): Argument type mismatch. Expected a string, but got #{coll.class}."
            )
          end

          idx = idx.as(String)

          !!coll[idx]?
        else
          raise ArgumentTypeError.new(
            "hasindex(coll, idx): Argument type mismatch. Expected a collection, but got #{coll.class}."
          )
        end
      end
    end
  end
end
