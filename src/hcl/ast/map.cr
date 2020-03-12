module HCL
  module AST
    class Map < Node
      getter :attributes

      def initialize(attributes : Hash(String, Node) = Hash(String, Node).new, **kwargs)
        super(**kwargs)

        @attributes = attributes
      end

      def as_json(ctx : ExpressionContext) : Any
        evaluate(ctx)
      end
    end
  end
end
