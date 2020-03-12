module HCL
  module AST
    class Identifier < Node
      def initialize(name : Symbol, **kwargs)
        super(name.to_s, **kwargs)
      end

      def initialize(*args, **kwargs)
        super(*args, **kwargs)
      end

      def name
        source
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
