module HCL
  module AST
    class TemplateForExpr < Node
      @value_name : String
      @coll_expr : Expression
      @tpl_expr : Template
      @key_name : String?

      getter :coll_expr, :value_name, :tpl_expr, :key_name

      def initialize(
        coll_expr : Expression,
        value_name : Identifier,
        tpl_expr : Template,
        key_name : Identifier? = nil,
        **kwargs
      )
        super(**kwargs)
        @coll_expr = coll_expr
        @value_name = value_name.to_s
        @tpl_expr = tpl_expr
        @key_name = key_name ? key_name.to_s : nil
      end

      def to_s(io : IO)
        io << "%{for "

        if key = key_name
          io << key
          io << ", "
        end

        io << value_name
        io << " in "
        coll_expr.to_s(io)
        io << "}"
        tpl_expr.to_s(io)
        io << "%{endfor}"
      end

      def value(ctx : ExpressionContext) : Any
        coll = coll_expr.value(ctx).as_h? || coll_expr.value(ctx).as_a

        index = 0

        builder = String.build do |str|
          coll.each do |item|
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

            str << tpl_expr.value(iter_ctx).to_s
          end
        end

        Any.new(builder.to_s)
      end
    end
  end
end
