module HCL
  module AST
    class ListToken < Token
      getter :children

      def initialize(peg_tuple : Pegmatite::Token, string : String)
        super(peg_tuple, string)
        @children = [] of Token
      end

      def <<(token : Token)
        @children << token
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
