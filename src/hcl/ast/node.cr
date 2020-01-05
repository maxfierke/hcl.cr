module HCL
  module AST
    abstract class Node
      @source : String
      @token : Pegmatite::Token?

      getter :source

      def initialize(source : String = "", token : Pegmatite::Token? = nil)
        @token = token
        @source = source
      end

      abstract def to_s(io : IO)
      abstract def value(ctx : ExpressionContext) : Any
    end
  end
end
