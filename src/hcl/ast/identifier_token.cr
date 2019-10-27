module HCL
  module AST
    class IdentifierToken < ValueToken
      def string
        source
      end

      def value : ValueType
        string
      end
    end
  end
end
