module HCL
  module AST
    class IdentifierToken < Token
      def string : String
        source
      end

      def value : ValueType
        string
      end
    end
  end
end
