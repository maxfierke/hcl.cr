module HCL
  module AST
    alias BlockLabel = Identifier | Literal
    alias Operand =
      Literal |
      Number |
      Expression
  end
end
