module HCL
  module AST
    class StringToken < Token
      def string : String
        "\"#{source}\""
      end

      def value : ValueType
        source
      end
    end
  end
end
