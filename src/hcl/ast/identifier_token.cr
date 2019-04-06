module HCL
  module AST
    class IdentifierToken < ValueToken
      def value
        string
      end
    end
  end
end
