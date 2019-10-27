module HCL
  module AST
    class ListToken < ValueToken
      getter :children

      def initialize(peg_tuple : Pegmatite::Token, string : String)
        super(peg_tuple, string)
        @children = [] of ValueToken
      end

      def <<(token : ValueToken)
        @children << token
      end

      def string
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
