module HCL
  module AST
    class TemplateInterpolation < Node
      getter :expression

      def initialize(expression : Expression, **kwargs)
        super(**kwargs)
        @expression = expression
      end
    end
  end
end
