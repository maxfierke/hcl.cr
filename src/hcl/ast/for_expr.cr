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

      def to_s(io : IO)
        io << start_tag
        io << "for "

        if key = key_name
          io << key
          io << ", "
        end

        io << value_name
        io << " in "
        coll_expr.to_s(io)
        io << ": "

        if key = key_expr
          key.to_s(io)
          io << " => "
        end
        value_expr.to_s(io)

        if cond = cond_expr
          io << " if "
          cond.to_s(io)
        end

        io << end_tag
      end

      def value(ctx : ExpressionContext) : Any
        if is_map_type?
          coll = coll_expr.value(ctx).as_h? || coll_expr.value(ctx).as_a
          key_expr = self.key_expr.not_nil!

          index = 0
          mapped = coll.reduce(Hash(String, Any).new) do |acc, item|
            if item.is_a?(Tuple)
              key, value = item
            else
              key = index.to_i64
              value = item
            end

            iter_ctx = ExpressionContext.new(ctx)

            if key_name = self.key_name
              iter_ctx.variables[key_name] = Any.new(key)
            end

            iter_ctx.variables[value_name] = value

            if cond = cond_expr
              if cond.value(iter_ctx).as_bool?
                key_val = key_expr.value(iter_ctx).to_s
                acc[key_val] = value_expr.value(iter_ctx)
              end
            else
              key_val = key_expr.value(iter_ctx).to_s
              acc[key_val] = value_expr.value(iter_ctx)
            end

            index += 1

            acc
          end

          Any.new(mapped)
        else
          coll = coll_expr.value(ctx).as_a

          index = 0
          mapped = coll.reduce(coll.class.new) do |acc, item|
            iter_ctx = ExpressionContext.new(ctx)
            iter_ctx.variables[value_name] = item
            if key = key_name
              iter_ctx.variables[key] = Any.new(index.to_i64)
            end

            if cond = cond_expr
              if cond.value(iter_ctx).as_bool?
                acc << value_expr.value(iter_ctx)
              end
            else
              acc << value_expr.value(iter_ctx)
            end

            index += 1

            acc
          end

          Any.new(mapped)
        end
      end

      private def is_map_type?
        for_type == TYPE_MAP
      end

      private def start_tag
        if is_map_type?
          "{"
        else
          "["
        end
      end

      private def end_tag
        if is_map_type?
          "}"
        else
          "]"
        end
      end
    end
  end
end
