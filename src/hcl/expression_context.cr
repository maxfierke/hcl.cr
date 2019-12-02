module HCL
  class ExpressionContext
    class ExpressionError < Exception; end
    class CallError < ExpressionError; end
    class ArityMismatchError < CallError; end
    class FunctionUndefinedError < CallError; end
    class VariableUndefinedError < ExpressionError; end

    @parent : ExpressionContext?
    @functions : Hash(String, Function)
    @variables : Hash(String, AST::ValueType)

    getter :parent, :functions, :variables

    def initialize(parent : ExpressionContext? = nil)
      @parent = parent
      @functions = Hash(String, Function).new
      @variables = Hash(String, AST::ValueType).new
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
