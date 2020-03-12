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

    enum Mode
      LITERAL
      FULL
    end

    @parent : ExpressionContext?
    @functions : Hash(String, Function) = Hash(String, Function).new
    @variables : Hash(String, Any) = Hash(String, Any).new

    property mode : Mode = Mode::FULL
    getter :parent, :functions, :mode, :variables

    def self.default_context
      ctx = new(nil)

      DEFAULT_FUNCTIONS.each do |function_class|
        func = function_class.new
        ctx.functions[func.name] = func
      end

      ctx
    end

    def initialize(parent : ExpressionContext? = nil, mode : Mode? = Mode::FULL)
      @parent = parent
      @mode = (parent ? parent.mode : nil) || mode
    end

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

    def full_eval?
      mode == Mode::FULL
    end

    def literal_only?
      mode == Mode::LITERAL
    end

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
