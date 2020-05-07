module HCL
  module AST
    abstract class Body < Node
      getter :attributes, :blocks

      def initialize(
        attributes : Hash(String, Node) = Hash(String, Node).new,
        blocks : Array(Block) = Array(Block).new,
        **kwargs
      )
        super(**kwargs)

        @attributes = attributes
        @blocks = blocks
      end
    end
  end
end
