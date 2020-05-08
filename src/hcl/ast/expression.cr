module HCL
  module AST
    class Expression < Node
      getter :children

      def initialize(children : Array(Node), **kwargs)
        super(**kwargs)
        @children = children
      end
    end
  end
end
