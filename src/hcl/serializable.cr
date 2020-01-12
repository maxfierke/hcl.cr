module HCL
  # Denotes an attribute within an HCL body (either a document or block).
  # Can be applied to getters, setters, `property`, and instance variables.
  #
  # See `HCL::Serializable` for more info.
  annotation Attribute
  end

  # Denotes a block within an HCL body (either a document or block).
  # Can be applied to getters, setters, `property`, and instance variables.
  #
  # See `HCL::Serializable` for more info.
  annotation Block
  end

  # Denotes a label within an HCL block
  # Can be applied to getters, setters, `property`, and instance variables.
  #
  # This attribute is order-dependent unless an `index` option is specified.
  #
  # See `HCL::Serializable` for more info.
  annotation Label
  end

  # The `HCL::Serializable` module automatically generates methods for HCL serialization and deserialization when included.
  #
  # ### Example
  #
  # ```
  # require "hcl"
  #
  # class Location
  #   include HCL::Serializable
  #
  #   @[HCL::Attribute(key: "lat")]
  #   property latitude : Float64
  #
  #   @[HCL::Attribute(key: "lng")]
  #   property longitude : Float64
  # end
  #
  # class House
  #   include HCL::Serializable
  #
  #   @[HCL::Attribute]
  #   property address : String
  #
  #   @[HCL::Block]
  #   property location : Location?
  # end
  #
  # hcl_house = <<-HCL
  #   address = "Crystal Road 1234"
  #   location {
  #     lat = 12.3
  #     lng = 34.5
  #   }
  #
  # HCL
  # house = House.from_hcl(hcl_house)
  # house.address  # => "Crystal Road 1234"
  # house.location # => #<Location:0x10cd93d80 @latitude=12.3, @longitude=34.5>
  # house.to_hcl  # => "
  #   address = \"Crystal Road 1234\"
  #
  #   location {
  #     lat = 12.3
  #     lng = 34.5
  #   }
  # "
  # ```
  #
  # ### Usage
  #
  # Including `HCL::Serializable` will create `#to_hcl` and `self.from_hcl` methods on the current class,
  # and a constructor which takes an `HCL::AST::Body` and an `HCL::ExpressionContext`.
  # By default, these methods serialize into an HCL document containing the value of every tagged instance
  # variable, the keys being the instance variable name. Most primitives and collections supported as
  # instance variable values (string, integer, array, hash, etc.), along with objects which define
  # `#to_hcl(builder : HCL::Builder)`.
  #
  # Union types are supported for attributes and blocks, including unions with `Nil`.
  # If multiple types in a union parse correctly, it is undefined which one will be chosen.
  #
  # To denote an individual instance variable to be parsed and serialized, the annotation `HCL::Attribute`
  # must be placed on the instance variable. Annotating property, getter and setter macros is also allowed.
  # ```
  # require "hcl"
  #
  # class A
  #   include HCL::Serializable
  #
  #   @[HCL::Attribute(key: "my_key", emit_null: true)]
  #   getter a : Int32?
  # end
  # ```
  #
  # `HCL::Attribute` properties:
  # * **key**: the value of the key in the HCL document or block (by default the name of the instance variable)
  # * **emit_null**: if `true`, emits a `null` value for nilable property (by default nulls are not emitted)
  #
  # Deserialization also respects default values of variables:
  # ```
  # require "hcl"
  #
  # struct A
  #   include HCL::Serializable
  #
  #   @[HCL::Attribute]
  #   @a : Int64
  #
  #   @[HCL::Attribute]
  #   @b : Float64 = 1.0
  # end
  #
  # A.from_hcl("a = 1\n") # => A(@a=1, @b=1.0)
  # ```
  #
  # ### Extensions: `HCL::Serializable::Strict` and `HCL::Serializable::Unmapped`.
  #
  # If the `HCL::Serializable::Strict` module is included, unknown properties in the HCL
  # document will raise a parse exception. By default the unknown properties
  # are silently ignored.
  # If the `HCL::Serializable::Unmapped` module is included, unknown attributes and blocks in the HCL
  # document will be stored in respective `Hash(String, HCL::AST::Node)`. For blocks,
  # any unmapped labels will be stored in a `Hash(Int32, HCL::AST::Node)`, where
  # the key is the label index. On serialization, any keys inside
  # `hcl_unmapped_attributes`, `hcl_unmapped_blocks`, and `hcl_unmapped_labels`
  # will be serialized and appended to the current HCL block or document.
  # The deserialied values are AST nodes in order to allow for later evaluation,
  # perhaps with a different expression context than the original document.
  # ```
  # require "hcl"
  #
  # struct A
  #   include HCL::Serializable
  #   include HCL::Serializable::Unmapped
  #
  #   @[HCL::Attribute]
  #   @a : Int32
  # end
  #
  # a = A.from_hcl("a = 1\nb = 2\n") # => A(@hcl_unmapped_attributes={"b" => HCL::AST::Number.new(2_i64)}, @a=1)
  # a.to_hcl # => "a = 1\nb = 2\n"
  # ```
  #
  #
  # ### Class annotation `HCL::Serializable::Options`
  #
  # supported properties:
  # * **emit_nulls**: if `true`, emits a `null` value for all nilable properties (by default nulls are not emitted)
  #
  # ```
  # require "hcl"
  #
  # @[HCL::Serializable::Options(emit_nulls: true)]
  # class A
  #   include HCL::Serializable
  #
  #   @[HCL::Serializable]
  #   @a : Int32?
  # end
  # ```
  #
  # This module is derived heavily from [JSON::Serializable](https://github.com/crystal-lang/crystal/blob/41bd18fbea4aec50aad33aa3beb7a0bf30544186/src/json/serialization.cr)
  module Serializable
    annotation Options
    end

    macro included
      # Define a `new` directly in the included type,
      # so it overloads well with other possible initializes

      def self.new(node : ::HCL::AST::Body, ctx : ::HCL::ExpressionContext)
        new_from_hcl_ast_node(node, ctx)
      end

      private def self.new_from_hcl_ast_node(node : ::HCL::AST::Body, ctx : ::HCL::ExpressionContext)
        instance = allocate
        instance.initialize(__node_from_hcl: node, __ctx_from_hcl: ctx)
        GC.add_finalizer(instance) if instance.responds_to?(:finalize)
        instance
      end

      # When the type is inherited, carry over the `new`
      # so it can compete with other possible intializes

      macro inherited
        def self.new(node : ::HCL::AST::Body, ctx : ::HCL::ExpressionContext)
          new_from_hcl_ast_node(node, ctx)
        end
      end
    end

    def initialize(*, __node_from_hcl : ::HCL::AST::Body, __ctx_from_hcl : ::HCL::ExpressionContext)
      {% begin %}
        # Collect instance variable configuration

        {% attributes = {} of Nil => Nil %}
        {% blocks = {} of Nil => Nil %}
        {% labels = {} of Nil => Nil %}
        {% current_label_idx = 0 %}
        {% for ivar in @type.instance_vars %}
          {% if ann = ivar.annotation(::HCL::Attribute) %}
            {%
              attributes[ivar.id] = {
                type:        ivar.type,
                key:         ((ann && ann[:key]) || ivar).id.stringify,
                has_default: ivar.has_default_value?,
                default:     ivar.default_value,
                nilable:     ivar.type.nilable?,
                presence:    ann && ann[:presence],
              }
            %}
          {% elsif ann = ivar.annotation(::HCL::Block) %}
            {%
              blocks[ivar.id] = {
                type:        ivar.type,
                key:         ((ann && ann[:key]) || ivar).id.stringify,
                has_default: ivar.has_default_value?,
                default:     ivar.default_value,
                nilable:     ivar.type.nilable?,
                presence:    ann && ann[:presence],
              }
            %}
          {% elsif ann = ivar.annotation(::HCL::Label) %}
            {%
              labels[ivar.id] = {
                type:        ivar.type,
                index:       ann[:index] || current_label_idx,
                has_default: ivar.has_default_value?,
                default:     ivar.default_value,
                nilable:     ivar.type.nilable?,
                presence:    ann && ann[:presence],
              }
            %}
            {% current_label_idx = ann[:index] ? (ann[:index] + 1) : (current_label_idx + 1) %}
          {% end %}
        {% end %}

        {% for name in (attributes.keys + blocks.keys + labels.keys) %}
          %var{name} = nil
          %found{name} = false
        {% end %}

        # Process Attributes

        __node_from_hcl.attributes.each do |key, attr_node|
          case key
          {% for name, value in attributes %}
            when {{value[:key]}}
              %found{name} = true
              %var{name} = attr_node.value(__ctx_from_hcl).raw
          {% end %}
          else
            on_unknown_hcl_attribute(__node_from_hcl, key, __ctx_from_hcl)
          end
        end

        {% for name, value in attributes %}
          {% unless value[:nilable] || value[:has_default] %}
            if %var{name}.nil? && !%found{name} && !::Union({{value[:type]}}).nilable?
              if __node_from_hcl.is_a?(::HCL::AST::Document)
                raise ::HCL::ParseException.new(
                  "Missing HCL attribute '{{value[:key].id}}' for document"
                )
              else
                raise ::HCL::ParseException.new(
                  "Missing HCL attribute '{{value[:key].id}}' for block '#{__node_from_hcl.id}'"
                )
              end
            end
          {% end %}

          {% if value[:nilable] %}
            {% if value[:has_default] != nil %}
              @{{name}} = %found{name} ? %var{name}.as({{value[:type]}}) : {{value[:default]}}
            {% else %}
              @{{name}} = %var{name}.as({{value[:type]}})
            {% end %}
          {% elsif value[:has_default] %}
            @{{name}} = %var{name}.nil? ? {{value[:default]}} : %var{name}.as({{value[:type]}})
          {% else %}
          {% end %}

          {% if value[:presence] %}
            @{{name}}_present = %found{name}
          {% end %}
        {% end %}

        # Process Blocks

        __node_from_hcl.blocks.each do |block_node|
          case block_node.id
          {% for name, value in blocks %}
            when {{value[:key]}}
            {% unless value[:type] < Array %}
              if %found{name}
                raise ::HCL::ParseException.new(
                  "Only one '{{value[:key].id}}' block is allowed. Another was defined earlier."
                )
              end
            {% end %}

              %found{name} = true

            {% if value[:type] < Array && !value[:type].type_vars.empty? %}
              %var{name} ||= {{value[:type]}}.new
              {% item_type = value[:type].type_vars.first %}
              %var{name} << {{item_type}}.new(block_node, __ctx_from_hcl)
            {% else %}
              {% for t in value[:type].union_types %}
              {% unless t == Nil %}
              if %var{name}.nil?
                %var{name} = {{t}}.new(block_node, __ctx_from_hcl) rescue nil
              end
              {% end %}
            {% end %}
            {% end %}
          {% end %}
          else
            on_unknown_hcl_block(__node_from_hcl, block_node.id, __ctx_from_hcl)
          end
        end

        {% for name, value in blocks %}
          {% unless value[:nilable] || value[:has_default] %}
            if %var{name}.nil? && !%found{name} && !::Union({{value[:type]}}).nilable?
              if __node_from_hcl.is_a?(::HCL::AST::Document)
                raise ::HCL::ParseException.new(
                  "Missing HCL block '{{value[:key].id}}' for document"
                )
              else
                raise ::HCL::ParseException.new(
                  "Missing HCL block '{{value[:key].id}}' for block '#{__node_from_hcl.id}'"
                )
              end
            end
          {% end %}

          {% if value[:nilable] %}
            {% if value[:has_default] != nil %}
              @{{name}} = %found{name} ? %var{name}.as({{value[:type]}}) : {{value[:default]}}
            {% else %}
              @{{name}} = %var{name}
            {% end %}
          {% elsif value[:has_default] %}
            @{{name}} = %var{name}.nil? ? {{value[:default]}} : %var{name}.as({{value[:type]}})
          {% else %}
            @{{name}} = (%var{name}).as({{value[:type]}})
          {% end %}

          {% if value[:presence] %}
            @{{name}}_present = %found{name}
          {% end %}
        {% end %}

        # Process labels

        if __node_from_hcl.is_a?(::HCL::AST::Block)
          __node_from_hcl.labels.each_with_index do |label, idx|
            case idx
          {% for name, value in labels %}
            when {{value[:index]}}
              %found{name} = true
              %var{name} = label.value(__ctx_from_hcl).raw
          {% end %}
            else
              on_unknown_hcl_label(__node_from_hcl, idx, __ctx_from_hcl)
            end
          end

          {% for name, value in labels %}
            {% unless value[:nilable] || value[:has_default] %}
              if %var{name}.nil? && !%found{name} && !::Union({{value[:type]}}).nilable?
                raise ::HCL::ParseException.new(
                  "Missing HCL label at index {{value[:index]}} for block '#{__node_from_hcl.id}'"
                )
              end
            {% end %}

            {% if value[:nilable] %}
              {% if value[:has_default] != nil %}
                @{{name}} = %found{name} ? %var{name}.as({{value[:type]}}) : {{value[:default]}}
              {% else %}
                @{{name}} = %var{name}
              {% end %}
            {% elsif value[:has_default] %}
              @{{name}} = %var{name}.nil? ? {{value[:default]}} : %var{name}.as({{value[:type]}})
            {% else %}
              @{{name}} = (%var{name}).as({{value[:type]}})
            {% end %}

            {% if value[:presence] %}
              @{{name}}_present = %found{name}
            {% end %}
          {% end %}
        else
          {% unless labels.keys.empty? %}
            raise ::HCL::ParseException.new(
              "Cannot extract labels for an HCL document. Labels are only supported on HCL blocks."
            )
          {% end %}
        end
      {% end %}
      after_initialize
    end

    def to_hcl(io : IO, node : AST::Node? = AST::Document.new)
      to_hcl(HCL::Builder.new(node)).to_s(io)
    end

    def to_hcl(builder : HCL::Builder)
      {% begin %}
        {% options = @type.annotation(::HCL::Serializable::Options) %}
        {% emit_nulls = options && options[:emit_nulls] %}
        {% attributes = {} of Nil => Nil %}
        {% blocks = {} of Nil => Nil %}
        {% labels = {} of Nil => Nil %}
        {% current_label_idx = 0 %}
        {% for ivar in @type.instance_vars %}
          {% if ann = ivar.annotation(::HCL::Attribute) %}
            {%
              attributes[ivar.id] = {
                key:       ((ann && ann[:key]) || ivar).id.stringify,
                emit_null: (ann && (ann[:emit_null] != nil) ? ann[:emit_null] : emit_nulls),
              }
            %}
          {% elsif ann = ivar.annotation(::HCL::Block) %}
            {%
              blocks[ivar.id] = {
                key: ((ann && ann[:key]) || ivar).id.stringify
              }
            %}
          {% elsif ann = ivar.annotation(::HCL::Label) %}
            {%
              labels[ivar.id] = {
                type:  ivar.type,
                index: ann[:index] || current_label_idx,
              }
            %}
            {% current_label_idx = ann[:index] ? (ann[:index] + 1) : (current_label_idx + 1) %}
          {% end %}
        {% end %}

        {% for name, value in attributes %}
          %var{name} = @{{name}}

          if !%var{name}.nil? || {{value[:emit_null]}}
            builder.attribute({{value[:key]}}) { %var{name} }
          end
        {% end %}

        {% for name, value in blocks %}
          %var{name} = @{{name}}

          if %var{name}.is_a?(Array)
            %var{name}.each do |block|
              builder.block({{value[:key]}}) do |block_builder|
                block.to_hcl(block_builder)
              end
            end
          elsif !%var{name}.nil?
            builder.block({{value[:key]}}) do |block_builder|
              %var{name}.to_hcl(block_builder)
            end
          end
        {% end %}

        {%
          sorted_labels = labels.to_a.sort_by do |item|
            label = item[1]
            label[:index]
          end
        %}

        {% for item in sorted_labels %}
          {% name = item[0] %}
          %var{name} = @{{name}}
          builder.label(%var{name}) if !%var{name}.nil?
        {% end %}
      {% end %}

      on_to_hcl(builder)

      builder
    end

    def to_hcl
      String.build do |builder|
        to_hcl(builder)
      end
    end

    protected def after_initialize
    end

    protected def on_unknown_hcl_attribute(node, key, ctx)
    end

    protected def on_unknown_hcl_block(node, key, ctx)
    end

    protected def on_unknown_hcl_label(node, idx, ctx)
    end

    protected def on_to_hcl(builder)
    end

    module Strict
      protected def on_unknown_hcl_attribute(node, key, ctx)
        if node.is_a?(::HCL::AST::Document)
          raise ::HCL::ParseException.new(
            "Unknown HCL attribute '#{key}' for document"
          )
        else
          raise ::HCL::ParseException.new(
            "Unknown HCL attribute '#{key}' for block '#{node.id}'"
          )
        end
      end

      protected def on_unknown_hcl_block(node, key, ctx)
        if node.is_a?(::HCL::AST::Document)
          raise ::HCL::ParseException.new(
            "Unknown HCL block '#{key}' for document"
          )
        else
          raise ::HCL::ParseException.new(
            "Unknown HCL block '#{key}' for block '#{node.id}'"
          )
        end
      end

      protected def on_unknown_hcl_label(node, idx, ctx)
        raise ::HCL::ParseException.new(
          "Unknown HCL label at index #{idx} for block '#{node.id}': #{node.labels[idx]}"
        )
      end
    end

    module Unmapped
      # Unmapped attribute nodes
      property hcl_unmapped_attributes = Hash(String, ::HCL::AST::Node).new

      # Unmapped block node groups
      property hcl_unmapped_blocks = Hash(String, Array(::HCL::AST::Block)).new

      # Unmapped label nodes
      property hcl_unmapped_labels = Hash(Int32, ::HCL::AST::Node).new

      protected def on_unknown_hcl_attribute(node, key, ctx)
        hcl_unmapped_attributes[key] = node.attributes[key]
      end

      protected def on_unknown_hcl_block(node, key, ctx)
        hcl_unmapped_blocks[key] = node.blocks.select { |block| block.id == key }
      end

      protected def on_unknown_hcl_label(node, idx, ctx)
        hcl_unmapped_labels[idx] = node.labels[idx]
      end

      protected def on_to_hcl(builder)
        builder_node = builder.node

        if builder_node.is_a?(::HCL::AST::Block)
          hcl_unmapped_labels.to_a.
            sort_by { |label_tuple| label_tuple[0] }.
            map { |label_tuple| label_tuple[1] }.
            each do |label|
              builder_node.labels << label.as(::HCL::AST::BlockLabel)
            end
        end

        if builder_node.is_a?(::HCL::AST::Body)
          hcl_unmapped_attributes.each do |key, attr_node|
            builder.attribute(key) { attr_node }
          end

          hcl_unmapped_blocks.each do |key, block_type|
            block_type.each do |block_node|
              builder_node.blocks << block_node
            end
          end
        else
          raise "Expected builder node to be an HCL::AST::Body, received #{builder_node.class}"
        end
      end
    end
  end
end
