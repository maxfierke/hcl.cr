module HCL
  module AST
    class Template < Node
      @quoted = false

      getter :children
      getter? :quoted

      def initialize(children : Array(Node), **kwargs)
        super(**kwargs)
        @children = children

        unless source.empty?
          @quoted = source[0] == '"' && source[source.size - 1] == '"'
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
