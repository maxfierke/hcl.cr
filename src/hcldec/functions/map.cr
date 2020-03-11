module HCLDec
  module Functions
    class Map < HCL::Function
      def initialize
        super(
          name: "map",
          arity: 1,
          varadic: false
        )
      end

      def call(args : Array(HCL::Any)) : HCL::Any
        str = args[0].as_s?

        if !str || !TYPES.includes?(str)
          raise ArgumentTypeError.new(
            "map(element_type): Argument type mismatch. Expected one of #{TYPES.map(&.lstrip(TYPE_PREFIX)).join(", ")}."
          )
        end

        HCL::Any.new("#{TYPE_PREFIX}_map(#{str.lstrip(TYPE_PREFIX)})")
      end
    end
  end
end
