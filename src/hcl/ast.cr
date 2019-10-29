module HCL
  module AST
    alias OperandToken =
      LiteralToken |
      NumberToken |
      ExpressionToken
    alias ValueType =
      Nil |
      Bool |
      String |
      Int64 |
      Float64 |
      Hash(String, ValueType) |
      Array(ValueType)
  end
end
