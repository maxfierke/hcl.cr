module HCLDec
  module Functions
    class List < HCL::Function
      def initialize
        super(
          name: "list",
          arity: 1,
          varadic: false
        )
      end

      def call(args : Array(HCL::Any)) : HCL::Any
        str = args[0].as_s?

        if !str || !TYPES.includes?(str)
          raise ArgumentTypeError.new(
            "list(element_type): Argument type mismatch. Expected one of #{TYPES.map(&.lstrip(TYPE_PREFIX)).join(", ")}."
          )
        end

        HCL::Any.new("#{TYPE_PREFIX}_list(#{str.lstrip(TYPE_PREFIX)})")
      end
    end
  end
end
