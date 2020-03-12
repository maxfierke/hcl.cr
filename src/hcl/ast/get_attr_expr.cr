module HCL
  module AST
    class GetAttrExpr < Node
      @attribute_name : String

      getter :attribute_name

      def initialize(attribute : Identifier, **kwargs)
        super(**kwargs)
        @attribute_name = attribute.name
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
