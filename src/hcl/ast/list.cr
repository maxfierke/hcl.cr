module HCL
  module AST
    class List < Node
      getter :children

      def initialize(**kwargs)
        super(**kwargs)
        @children = [] of Node
      end

      def <<(node : Node)
        @children << node
      end

      def as_json(ctx : ExpressionContext) : Any
        evaluate(ctx)
      end
    end
  end
end
