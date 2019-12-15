module HCL
  abstract class Function
    class FunctionEvalError < Exception; end
    class FunctionArgumentError < FunctionEvalError; end
    class ArgumentTypeError < FunctionArgumentError; end

    ARG_MAX = 100_u32

    @arity : UInt32 | Range(UInt32, UInt32)

    getter :name, :arity
    getter? :varadic

    def initialize(name : String, arity : UInt32 | Range(UInt32, UInt32), varadic = false)
      @name = name
      @arity = arity
      @varadic = varadic
    end

    def matches_arity?(args_size : Range(UInt32, UInt32)) : Bool
      args_size.all? { |s| matches_arity?(s) }
    end

    def matches_arity?(args_size) : Bool
      ar = arity

      case ar
      when Range(UInt32, UInt32)
        ar.includes?(args_size)
      else
        ar == args_size
      end
    end

    abstract def call(args : Array(ValueType)) : ValueType
  end
end
