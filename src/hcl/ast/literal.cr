module HCL
  module AST
    class Literal < Node
      @value : Any?

      NULL_STR = "null"
      TRUE_STR = "true"
      FALSE_STR = "false"

      def to_s(io : IO)
        if ![NULL_STR, TRUE_STR, FALSE_STR].includes?(source)
          io << "\""
          io << source
          io << "\""
        else
          io << source
        end
      end

      def value(ctx : ExpressionContext) : Any
        if source == TRUE_STR
          Any.new(true)
        elsif source == FALSE_STR
          Any.new(false)
        elsif source == NULL_STR
          Any.new(nil)
        else
          Any.new(source)
        end
      end
    end
  end
end
