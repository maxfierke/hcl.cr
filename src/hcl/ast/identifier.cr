module HCL
  module AST
    class Identifier < Node
      def string : String
        source
      end

      def value : ValueType
        string
      end
    end
  end
end
