module HCL
  module AST
    class StringValue < Node
      def string : String
        "\"#{source}\""
      end

      def value : ValueType
        source
      end
    end
  end
end
