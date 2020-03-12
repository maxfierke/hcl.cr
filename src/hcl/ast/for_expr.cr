module HCL
  module AST
    class ForExpr < Node
      TYPE_LIST = :list
      TYPE_MAP  = :map

      @for_type : Symbol
      @value_name : String
      @coll_expr : Expression
      @value_expr : Expression
      @key_name : String?
      @key_expr : Expression?
      @cond_expr : Expression?

      getter :for_type, :coll_expr, :value_name, :value_expr, :key_name, :key_expr, :cond_expr

      def initialize(
        for_type : Symbol,
        coll_expr : Expression,
        value_name : Identifier,
        value_expr : Expression,
        key_name : Identifier? = nil,
        key_expr : Expression? = nil,
        cond_expr : Expression? = nil,
        **kwargs
      )
        super(**kwargs)
        @for_type = for_type
        @coll_expr = coll_expr
        @value_name = value_name.to_s
        @value_expr = value_expr
        @key_name = key_name ? key_name.to_s : nil
        @key_expr = key_expr
        @cond_expr = cond_expr
      end

      def as_json(ctx : ExpressionContext) : Any
        case ctx.mode
        when ExpressionContext::Mode::LITERAL
          Any.new(to_s)
        else
          evaluate(ctx)
        end
      end

      def is_map_type?
        for_type == TYPE_MAP
      end

      def start_tag
        if is_map_type?
          "{"
        else
          "["
        end
      end

      def end_tag
        if is_map_type?
          "}"
        else
          "]"
        end
      end
    end
  end
end
