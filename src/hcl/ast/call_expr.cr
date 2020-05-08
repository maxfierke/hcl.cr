module HCL
  module AST
    class CallExpr < Node
      getter :id, :args
      getter? :varadic

      def initialize(
        id : String,
        args : Array(Node),
        varadic : Bool,
        **kwargs
      )
        super(**kwargs)

        @id = id
        @args = args
        @varadic = varadic
      end
    end
  end
end
