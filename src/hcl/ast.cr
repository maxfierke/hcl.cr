module HCL
  module AST
    alias BlockLabel = Identifier | StringValue
    alias Operand =
      Literal |
      Number |
      Expression
  end
end
