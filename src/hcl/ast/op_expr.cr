module HCL
  module AST
    class OpExpr < Node
      getter :operator, :left_operand, :right_operand

      ADDITION    = :+
      SUBTRACTION = :-
      MULTIPLY    = :*
      DIVIDE      = :/
      MOD         = :%
      EQ          = :==
      NEQ         = :"!="
      LT          = :<
      GT          = :>
      GTE         = :>=
      LTE         = :<=
      AND         = :"&&"
      OR          = :"||"
      NOT         = :"!"

      def initialize(
        operator : String,
        left_operand : Node,
        right_operand : Node?,
        **kwargs
      )
        super(**kwargs)

        @operator = case operator
                    when "+"  then ADDITION
                    when "-"  then SUBTRACTION
                    when "*"  then MULTIPLY
                    when "/"  then DIVIDE
                    when "%"  then MOD
                    when "==" then EQ
                    when "!=" then NEQ
                    when "<"  then LT
                    when ">"  then GT
                    when ">=" then GTE
                    when "<=" then LTE
                    when "&&" then AND
                    when "||" then OR
                    when "!"  then NOT
                    else
                      raise "BUG: unsupported operator: #{operator}"
                    end
        @left_operand = left_operand
        @right_operand = right_operand
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
