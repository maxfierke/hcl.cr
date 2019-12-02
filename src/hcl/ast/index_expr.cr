module HCL
  module AST
    class IndexExpr < Node
      getter :index_exp

      def initialize(
        peg_tuple : Pegmatite::Token,
        source : String,
        index_exp : Expression
      )
        super(peg_tuple, source)

        @index_exp = index_exp
      end

      def string : String
        "[#{index_exp.string}]"
      end

      def value(ctx : ExpressionContext) : ValueType
        raise "BUG: This should not be called, as there is no value to represent."
      end
    end
  end
end
