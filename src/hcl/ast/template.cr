module HCL
  module AST
    class Template < Node
      @quoted = false

      getter :children
      getter? :quoted

      def initialize(children : Array(Node), **kwargs)
        super(**kwargs)
        @children = children
        unless source.empty?
          @quoted = source[0] == '"' && source[source.size - 1] == '"'
        end
      end

      def as_json(ctx : ExpressionContext) : Any
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(to_s)
        else
          evaluate(ctx)
        end
      end
    end
  end
end
