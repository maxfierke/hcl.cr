module HCL
  module AST
    class List < Node
      getter :children

      def initialize(peg_tuple : Pegmatite::Token, string : String)
        super(peg_tuple, string)
        @children = [] of Node
      end

      def <<(node : Node)
        @children << node
      end

      def string : String
        "[#{children.map(&.string).join(", ")}]"
      end

      def value : ValueType
        children.map do |item|
          item.value.as(ValueType)
        end
      end
    end
  end
end
