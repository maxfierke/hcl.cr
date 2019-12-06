module HCL
  abstract class Function
    @arity : UInt32 | Range(UInt32, UInt32)

    getter :name, :arity
    getter? :varadic

    def initialize(name : String, arity : UInt32, varadic = false)
      @name = name
      @arity = arity
      @varadic = varadic
    end

    def matches_arity?(args_size : Range(UInt32, UInt32)) : Bool
      arity.includes?(args_size)
    end

    def matches_arity?(args_size) : Bool
      arity == args_size
    end

    abstract def call(args : Array(ValueType)) : AST::ValueType
  end
end
