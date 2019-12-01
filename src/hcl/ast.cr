module HCL
  module AST
    alias OperandNode =
      LiteralNode |
      NumberNode |
      ExpressionNode
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
