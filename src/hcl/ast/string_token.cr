module HCL
  module AST
    class StringToken < ValueToken
      def string
        "\"#{source}\""
      end

      def value
        source
      end
    end
  end
end
