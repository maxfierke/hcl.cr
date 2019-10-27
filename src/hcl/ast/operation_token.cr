module HCL
  module AST
    class OperationToken < ValueToken
      getter :operator, :left_operand, :right_operand

      ADDITION = :+
      SUBTRACTION = :-
      MULTIPLY = :*
      DIVIDE = :/
      MOD = :%
      EQ = :==
      NEQ = :"!="
      LT = :<
      GT = :>
      GTE = :>=
      LTE = :<=
      AND = :"&&"
      OR = :"||"
      NOT = :"!"

      def initialize(
        peg_tuple : Pegmatite::Token,
        string : String,
        operator : String,
        left_operand : ValueToken,
        right_operand : Nil | ValueToken
      )
        super(peg_tuple, string)

        @operator = case operator
          when "+" then ADDITION
          when "-" then SUBTRACTION
          when "*" then MULTIPLY
          when "/" then DIVIDE
          when '%' then MOD
          when "==" then EQ
          when "!=" then NEQ
          when "<" then LT
          when ">" then GT
          when ">=" then GTE
          when "<=" then LTE
          when "&&" then AND
          when "||" then OR
          when "!" then NOT
          else
            raise "BUG: unsupported operator: #{operator}"
          end
        @left_operand = left_operand
        @right_operand = right_operand
      end

      def string
        if right_operand.nil?
          "#{operator}#{left_operand.string}"
        else
          "#{left_operand.string} #{operator} #{right_operand.not_nil!.string}"
        end
      end

      def value : ValueType
        # This is wrong, but haven't implemented function
        # call evaluation yet.
        nil
      end
    end
  end
end
