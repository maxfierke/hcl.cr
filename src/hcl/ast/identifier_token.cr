module HCL
  module AST
    class IdentifierToken < ValueToken
      def string
        source
      end

      def value
        string
      end
    end
  end
end
