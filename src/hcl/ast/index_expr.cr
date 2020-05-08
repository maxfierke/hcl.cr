module HCL
  module AST
    class IndexExpr < Node
      getter :index_exp

      def initialize(index_exp : Expression, **kwargs)
        super(**kwargs)
        @index_exp = index_exp
      end
    end
  end
end
