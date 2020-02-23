module HCL
  module AST
    class Template < Node
      getter :children

      def initialize(children : Array(Node), **kwargs)
        super(**kwargs)
        @children = children
      end

      def to_s(io : IO)
        if children.size == 1
          children.first.to_s(io)
        else
          io << "\""
          children.each do |exp|
            exp.to_s(io)
          end
          io << "\""
        end
      end

      def value(ctx : ExpressionContext) : Any
        if children.size == 1
          children.first.value(ctx)
        else
          builder = String.build do |str|
            children.each do |exp|
              # TODO: Validate stringiness
              str << exp.value(ctx).to_s
            end
          end

          HCL::Any.new(builder.to_s)
        end
      end
    end
  end
end
