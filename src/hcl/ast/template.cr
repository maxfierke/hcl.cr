module HCL
  module AST
    class Template < Node
      @quoted : Bool? = nil

      getter :children

      def initialize(children : Array(Node), **kwargs)
        super(**kwargs)
        @children = children
      end

      def to_s(io : IO)
        children.each do |exp|
          case exp
          when Literal
            exp.to_s(io, quoted: false)
          else
            exp.to_s(io)
          end
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

      def quoted?
        if (q = @quoted).nil? && !source.empty?
          @quoted = source[0] == '"' && source[source.size - 1] == '"'
        end

        @quoted
      end
    end
  end
end
