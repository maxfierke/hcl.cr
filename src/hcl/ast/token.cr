module HCL
  module AST
    abstract class Token
      @kind : Symbol

      getter :string, :kind

      def initialize(peg_tuple : Pegmatite::Token, string : String)
        kind, src_start, src_finish = peg_tuple
        @kind = kind
        @string = string
      end

      def as_s
        string
      end

      abstract def value
    end
  end
end
