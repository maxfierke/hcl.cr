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

      def accept(visitor)
        visitor.visit(self)
      end

      def evaluate(ctx : ExpressionContext)
        visitor = Visitors::Evaluator.new(ctx)
        self.accept(visitor)
      end

      def inspect(io)
        to_s(io)
      end

      def to_s(io : IO)
        visitor = Visitors::ToSVisitor.new(io)
        self.accept(visitor)
      end

      # DEPRECATED: Use `evaluate`
      def value(ctx : ExpressionContext) : Any
        evaluate(ctx)
      end
    end
  end
end
