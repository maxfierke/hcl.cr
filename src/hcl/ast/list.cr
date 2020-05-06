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

      def value(ctx : ExpressionContext) : Any
        result = children.map do |item|
          item.value(ctx)
        end

        Any.new(result)
      end
    end
  end
end
