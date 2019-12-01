module HCL
  module AST
    alias BlockLabel = Identifier | StringValue
    alias Operand =
      Literal |
      Number |
      Expression
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
