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

      def value(ctx : ExpressionContext) : Any
        if source == TRUE_STR
          Any.new(true)
        elsif source == FALSE_STR
          Any.new(false)
        else
          Any.new(nil)
        end
      end
    end
  end
end
