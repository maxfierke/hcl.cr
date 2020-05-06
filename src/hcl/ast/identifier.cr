module HCL
  module AST
    class Identifier < Node
      def initialize(name : Symbol, **kwargs)
        super(name.to_s, **kwargs)
      end

      def initialize(*args, **kwargs)
        super(*args, **kwargs)
      end

      def value
        source
      end

      def value(ctx : ExpressionContext) : Any
        ctx.lookup_var(to_s)
      end
    end
  end
end
