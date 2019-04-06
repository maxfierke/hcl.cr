module HCL
  module AST
    alias ValueType =
      Nil |
      Bool |
      String |
      NumberToken::Value |
      CallToken::Value |
      Hash(String, ValueType) |
      Array(ValueType)
  end
end
