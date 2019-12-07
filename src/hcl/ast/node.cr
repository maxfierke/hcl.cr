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

      abstract def to_s(io : IO)
      abstract def value(ctx : ExpressionContext) : ValueType
    end
  end
end
