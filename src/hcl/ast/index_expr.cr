module HCL
  module AST
    class IndexExpr < Node
      getter :index_exp

      def initialize(index_exp : Expression, **kwargs)
        super(**kwargs)
        @index_exp = index_exp
      end

      def value(ctx : ExpressionContext) : Any
        raise "BUG: This should not be called, as there is no value to represent."
      end
    end
  end
end
