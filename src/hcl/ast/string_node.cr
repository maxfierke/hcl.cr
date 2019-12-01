module HCL
  module AST
    class StringNode < Node
      def string : String
        "\"#{source}\""
      end

      def value : ValueType
        source
      end
    end
  end
end
