module HCL
  class Builder
    getter :node

    def self.build(node : AST::Node? = AST::Document.new)
      new(node).tap do |builder|
        yield builder
      end
    end

    def initialize(@node : AST::Node)
    end

    def to_hcl(_builder : HCL::Builder)
      node
    end

    def to_hcl(io : IO)
      node.to_s(io)
    end

    def to_s(io : IO)
      to_hcl(io)
    end

    def <<(value : AST::Node)
      n = node
      if n.is_a?(AST::List)
        n << value_to_node(value)
      else
        raise "Cannot use << inside non-list node."
      end
    end

    def <<(value)
      self << value_to_node(value)
    end

    def attribute(name, &block)
      n = node
      if n.is_a?(AST::Body) || n.is_a?(AST::Map)
        value = yield self
        value_node = value_to_node(value)
        n.attributes[name.to_s] = value_node
      else
        raise "Cannot add attribute to non-body node. Must be inside a document or block."
      end
    end

    def block(name, *args, &block)
      if (n = node).is_a?(AST::Body)
        block_node = block_node_for_name_and_labels(name, *args)

        self.class.build(block_node) do |builder|
          yield builder
        end

        n.blocks << block_node
      else
        raise "Cannot add block to non-body node. Must be inside a document or block."
      end
    end

    def identifier(value)
      AST::Identifier.new(value)
    end

    def label(value : Symbol | String)
      n = node

      if !n.is_a?(AST::Block)
        raise "Cannot add a label to non-block node. Must be inside a block."
      end

      case value
      when Symbol
        n.labels << AST::Identifier.new(value)
      when String
        n.labels << AST::Literal.new(value)
      end
    end

    def literal(value : Bool)
      AST::Literal.new(value.to_s)
    end

    def literal(value)
      AST::Literal.new(value)
    end

    def map(&block)
      self.class.build(AST::Map.new) do |builder|
        yield builder
      end
    end

    def number(value)
      case value
      when Float32
        AST::Number.new(value.to_f64)
      when Int32
        AST::Number.new(value.to_i64)
      when Float64, Int64
        AST::Number.new(value)
      else
        raise "#{value.class} cannot be used as a number value."
      end
    end

    def list(&block)
      self.class.build(AST::List.new) do |builder|
        yield builder
      end
    end

    private def assert_value_node!(possible_value_node)
      unless possible_value_node.is_a?(AST::Identifier) ||
        possible_value_node.is_a?(AST::Literal) ||
        possible_value_node.is_a?(AST::Number) ||
        possible_value_node.is_a?(AST::Map) ||
        possible_value_node.is_a?(AST::List)
        raise "#{possible_value_node.class} cannot be used as a value inside #{node.class}"
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
        value
      when .responds_to?(:to_hcl)
        n = value.to_hcl(self)
        n = n.node if n.is_a?(HCL::Builder)
        assert_value_node!(n)
        n
      else
        raise "#{value.class} could not be mapped to an HCL::AST::Node. Please use one of the builder helper methods instead or implement #to_hcl(builder : HCL::Builder)."
      end
    end
  end
end
