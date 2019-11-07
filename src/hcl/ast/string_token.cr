module HCL
  module AST
    class StringToken < ValueToken
      def string
        "\"#{source}\""
      end

      def value : ValueType
        source
      end
    end
  end
end
