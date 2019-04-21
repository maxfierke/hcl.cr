module HCL
  module AST
    class ExpressionToken < ValueToken
      getter :expression, :context

      def initialize(
        peg_tuple : Pegmatite::Token,
        source : String,
        expression : ValueToken,
        context : ExpressionContext
      )
        super(peg_tuple, source)

        @expression = expression
        @context = context
      end

      def string
        exp = @expression
        case exp
        when ExpressionToken
          "(#{exp.string})"
        else
          exp.string
        end
      end

      def value
        expression.value
      end
    end
  end
end
