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

      def to_s(io : IO)
        io << "["
        children.each_with_index do |node, index|
          node.to_s(io)

          if index != (children.size - 1)
            io << ", "
          end
        end

        io << "]"
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
