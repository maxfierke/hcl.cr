module HCL
  module AST
    abstract class Node
      @kind : Symbol

      getter :source, :kind

      def initialize(peg_tuple : Pegmatite::Token, source : String)
        kind, src_start, src_finish = peg_tuple
        @kind = kind
        @source = source
      end

      def as_s
        string
      end

      abstract def string : String
      abstract def value(ctx : ExpressionContext) : ValueType
    end
  end
end
