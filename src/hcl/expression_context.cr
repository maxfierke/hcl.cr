module HCL
  class ExpressionContext
    DEFAULT_FUNCTIONS = [
      Functions::Abs,
      Functions::Coalesce,
      Functions::Compact,
      Functions::Concat,
      Functions::Format,
      Functions::HasIndex,
      Functions::Int,
      Functions::JSONDecode,
      Functions::JSONEncode,
      Functions::Length,
      Functions::Lower,
      Functions::Max,
      Functions::Min,
      Functions::SetHas,
      Functions::SetIntersection,
      Functions::SetSubtract,
      Functions::SetSymDiff,
      Functions::SetUnion,
      Functions::Strlen,
      Functions::Substr,
      Functions::Upper,
    ]

    @parent : ExpressionContext?
    @functions : Hash(String, Function)
    @variables : Hash(String, Any)

    getter :parent, :functions, :variables

    # The default HCL expression context with all built-in default functions
    # registered
    def self.default_context
      ctx = new(nil)

      DEFAULT_FUNCTIONS.each do |function_class|
        func = function_class.new
        ctx.functions[func.name] = func
      end

      ctx
    end

    # Construct an empty expression context, optionally with a given parent
    def initialize(parent : ExpressionContext? = nil)
      @parent = parent
      @functions = Hash(String, Function).new
      @variables = Hash(String, Any).new
    end

    # Call a function defined within the current context or a parent context.
    #
    # Raises `HCL::FunctionUndefinedError` if function is not defined.
    # Raises `HCL::ArityMismatchError` if function arity is not satisfied.
    def call_func(name, args)
      current_ctx = self
      func = nil

      while current_ctx
        break if func = functions[name]?
        current_ctx = current_ctx.parent
      end

      if !func
        raise FunctionUndefinedError.new(
          "Function '#{name}' is not defined in scope of this expression"
        )
      end

      if !func.matches_arity?(args.size)
        raise ArityMismatchError.new(
          "Expected #{func.arity} arguments but found #{args.size}"
        )
      end

      func.call(args)
    end

    # Look up a variable starting with the current context, traversing parents
    # until a match is found.
    #
    # Raises `HCL::VariableUndefinedError` if variable is not defined.
    def lookup_var(name)
      current_ctx = self
      var = nil

      while current_ctx
        break if var = variables[name]?
        current_ctx = current_ctx.parent
      end

      if !var
        raise VariableUndefinedError.new(
          "Variable '#{name}' is not defined in scope of this expression"
        )
      end

      var
    end
  end
end
