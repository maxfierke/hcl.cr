module HCL
  module AST
    class Literal < Node
      @value : Nil | Bool

      NULL_STR = "null"
      TRUE_STR = "true"
      FALSE_STR = "false"

      def to_s(io : IO)
        io << source
      end

      def value(ctx : ExpressionContext) : ValueType
        if source == TRUE_STR
          ValueType.new(true)
        elsif source == FALSE_STR
          ValueType.new(false)
        else
          ValueType.new(nil)
        end
      end
    end
  end
end
