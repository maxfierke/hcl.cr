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
        **kwargs,
      )
        super(**kwargs)
        @coll_expr = coll_expr
        @value_name = value_name.to_s
        @tpl_expr = tpl_expr
        @key_name = key_name ? key_name.to_s : nil
      end
    end
  end
end
