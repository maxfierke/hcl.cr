module HCL
  module AST
    class Identifier < Node
      def initialize(name : Symbol, **kwargs)
        super(name.to_s, **kwargs)
      end

      def initialize(*args, **kwargs)
        super(*args, **kwargs)
      end

      def name
        source
      end
    end
  end
end
