module HCL
  module AST
    alias BlockLabel = Identifier | Literal
    alias Operand = Literal |
                    Number |
                    Expression
    enum LiteralType
      Unknown
      Null
      Bool
      String

      def null?
        self == LiteralType::Null
      end

      def bool?
        self == LiteralType::Bool
      end

      def string?
        self == LiteralType::String
      end
    end
  end
end
