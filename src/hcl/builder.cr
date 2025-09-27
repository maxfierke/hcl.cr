module HCL
  # An HCL builder helps build a valid HCL abstract syntax tree.
  #
  # An `HCL::BuildError` will be raised on any attempts to create an AST
  # that would be invalid (e.g. setting an attribute's value to a block)
  #
  # ```
  # require "hcl"
  #
  # string = HCL.build do |hcl|
  #   hcl.block "aws_instance", "c4.xlarge" do |blk|
  #     blk.attribute "security_group_ids" do
  #       blk.list do |l|
  #         l << l.literal("sg-123")
  #         l << l.literal("sg-456")
  #       end
  #     end
  #     blk.attribute("region") { "us-west-2" }
  #     blk.block("tags") do |t|
  #       t.attribute("name") { "test" }
  #     end
  #   end
  # end
  # string # => "aws_instance \"c4.xlarge\" {\n  security_group_ids = [\"sg-123\", \"sg-456\"]\n  region = \"us-west-2\"\n  tags {\n    name = \"test\"\m}"
  # ```
  class Builder
    getter :node

    # Yields an `HCL::Builder` instance for the given root node, which defaults to
    # `HCL::AST::Document`. Returns the `HCL::Builder` instance.
    def self.build(node : AST::Node? = AST::Document.new, &)
      new(node).tap do |builder|
        yield builder
      end
    end

    # Instantiate's a new `HCL::Builder` with the given root node. This
    # generally does not need to be invoked directly.
    def initialize(@node : AST::Node)
    end

    # Returns the `HCL::AST::Node` for the builder.
    def to_hcl(_builder : HCL::Builder)
      node
    end

    # Writes a string representation of the HCL node to the given IO.
    def to_hcl(io : IO)
      node.to_s(io)
    end

    # Alias for `#to_hcl(io : IO)`.
    def to_s(io : IO)
      to_hcl(io)
    end

    def to_json(json : JSON::Builder, ctx : ExpressionContext? = ExpressionContext.default_context)
      node.to_json(json, ctx)
    end

    def to_json(io : IO, ctx : ExpressionContext? = ExpressionContext.default_context)
      JSON.build(io) do |json|
        to_json(json, ctx)
      end
    end

    def to_json(ctx : ExpressionContext? = ExpressionContext.default_context)
      JSON.build do |json|
        to_json(json, ctx)
      end
    end

    # Appends an `HCL::AST::Node` to the underlying list node. Raises if the builder is not
    # for a list or if the node is not usable within a list.
    def <<(value : AST::Node)
      n = node
      if n.is_a?(AST::List)
        n << value_to_node(value)
      else
        raise BuildError.new("Cannot use << inside non-list node.")
      end
    end

    # Appends a value to the the underlying list node. Value most be convertable
    # to HCL, either through base types supported by the library or a
    # `#to_hcl(builder : HCL::Builder)` method on the object.
    #
    # Raises if the builder is not for a list or if the node is not usable
    # within a list.
    def <<(value)
      self << value_to_node(value)
    end

    # Adds an attribute to the open HCL body or map/object with the value of the
    # passed in block. Value must by an AST node or an object convertable to HCL,
    # either through base types supported by the library or a
    # `#to_hcl(builder : HCL::Builder)` method on the object.
    def attribute(name, &block)
      n = node
      if n.is_a?(AST::Body) || n.is_a?(AST::Map)
        value = yield self
        value_node = value_to_node(value)
        n.attributes[name.to_s] = value_node
      else
        raise BuildError.new(
          "Cannot add attribute to non-body node. Must be inside a document or block."
        )
      end
    end

    # Yields a new `HCL::Builder` for building a block. Adds the block to the
    # open HCL body. `name` is the first parameter, but subsequent parameters are
    # used as label values on the block. `#label` may also be used within the
    # block to set labels.
    #
    # Raises if used within a non-body node (i.e. not a document or block)
    def block(name, *args, &block)
      if (n = node).is_a?(AST::Body)
        block_node = block_node_for_name_and_labels(name, *args)

        self.class.build(block_node) do |builder|
          yield builder
        end

        n.blocks << block_node
      else
        raise BuildError.new(
          "Cannot add block to non-body node. Must be inside a document or block."
        )
      end
    end

    # Returns a new `AST::Identifier` node for the given value.
    def identifier(value)
      AST::Identifier.new(value)
    end

    # Appends a new `AST::BlockLabel` node with the given value to the block's
    # labels collection.
    #
    # Raises if active node is not a block.
    def label(value : Symbol | String)
      n = node

      if !n.is_a?(AST::Block)
        raise BuildError.new(
          "Cannot add a label to non-block node. Must be inside a block."
        )
      end

      case value
      when Symbol
        n.labels << AST::Identifier.new(value)
      when String
        n.labels << AST::Literal.new(value)
      end
    end

    # Yields a new `HCL::Builder` for building a list.
    def list(&block)
      self.class.build(AST::List.new) do |builder|
        yield builder
      end
    end

    # Returns a new `AST::Literal` node for the given boolean value.
    def literal(value : Bool)
      AST::Literal.new(value.to_s)
    end

    # Returns a new `AST::Literal` node for the given value.
    def literal(value)
      AST::Literal.new(value)
    end

    # Yields a new `HCL::Builder` for building a map/object.
    def map(&block)
      self.class.build(AST::Map.new) do |builder|
        yield builder
      end
    end

    # Returns a new `AST::Number` node with the given value
    #
    # Raises if value cannot be used or converted to a supported number format
    def number(value)
      case value
      when Float32
        AST::Number.new(value.to_f64)
      when Int32
        AST::Number.new(value.to_i64)
      when Float64, Int64
        AST::Number.new(value)
      else
        raise BuildError.new("#{value.class} cannot be used as a number value.")
      end
    end

    private def assert_value_node!(possible_value_node)
      unless possible_value_node.is_a?(AST::Identifier) ||
             possible_value_node.is_a?(AST::Expression) ||
             possible_value_node.is_a?(AST::Literal) ||
             possible_value_node.is_a?(AST::Number) ||
             possible_value_node.is_a?(AST::Map) ||
             possible_value_node.is_a?(AST::List)
        raise BuildError.new(
          "#{possible_value_node.class} cannot be used as a value inside #{node.class}"
        )
      end
      possible_value_node
    end

    private def block_node_for_name_and_labels(name, *args : String | Symbol)
      label_nodes = args.map { |l| value_to_node(l).as(AST::BlockLabel) }.to_a.as(Array(AST::BlockLabel))
      AST::Block.new(name, label_nodes)
    end

    private def block_node_for_name_and_labels(name)
      AST::Block.new(name)
    end

    private def value_to_node(value) : AST::Node
      case value
      when AST::Node
        assert_value_node!(value)
      when .responds_to?(:to_hcl)
        n = value.to_hcl(self)
        n = n.node if n.is_a?(HCL::Builder)
        assert_value_node!(n)
      else
        raise BuildError.new(
          "#{value.class} could not be mapped to an HCL::AST::Node. Please use one of the builder helper methods instead, pass an HCL::AST::Node, or implement #to_hcl(builder : HCL::Builder)."
        )
      end
    end
  end
end
