module HCL
  module AST
    class Expression < Node
      getter :children

      def initialize(children : Array(Node), **kwargs)
        super(**kwargs)
        @children = children
      end

      def as_json(ctx : ExpressionContext) : Any
        if children.size == 1
          child = children.first.not_nil!
          case child
          when List, Map, Number
            return child.as_json(ctx)
          when Expression, Template
            return Any.new(to_s)
          end
        end

        if ctx.literal_only?
          Any.new("${#{to_s}}")
        else
          Any.new(to_s)
        end
      end
    end
  end
end
