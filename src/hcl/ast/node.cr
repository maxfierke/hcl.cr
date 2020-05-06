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

      def inspect(io)
        to_s(io)
      end

      def to_s(io : IO)
        visitor = Visitors::ToSVisitor.new(io)
        self.accept visitor
      end

      abstract def value(ctx : ExpressionContext) : Any

      def accept(visitor)
        if visitor.visit_any(self)
          if visitor.visit(self)
            accept_children(visitor)
          end
          visitor.end_visit(self)
          visitor.end_visit_any(self)
        end
      end

      def accept_children(visitor)
      end
    end
  end
end
