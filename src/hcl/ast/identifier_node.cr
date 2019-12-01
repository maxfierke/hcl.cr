module HCL
  module AST
    class IdentifierNode < Node
      def string : String
        source
      end

      def value : ValueType
        string
      end
    end
  end
end
