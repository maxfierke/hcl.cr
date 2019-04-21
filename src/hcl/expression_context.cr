module HCL
  class ExpressionContext
    @parent : ExpressionContext?

    def initialize(
      parent : ExpressionContext? = nil
    )
      @parent = parent
    end
  end
end
