module HCL
  annotation Attribute
  end

  annotation Block
  end

  annotation Label
  end

  # The `HCL::Serializable` module automatically generates methods for HCL serialization when included.
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
  #   property address : String
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
  #   location {
  #     lat = 12.3
  #     lng = 34.5
  #   }
  # "
  # TODO: Check this:
  # houses = Array(House).from_hcl(%([{"address": "Crystal Road 1234", "location": {"lat": 12.3, "lng": 34.5}}]))
  # houses.size    # => 1
  # houses.to_json # => %([{"address":"Crystal Road 1234","location":{"lat":12.3,"lng":34.5}}])
  # ```
  #
  # ### Usage
  #
  # Including `HCL::Serializable` will create `#to_hcl` and `self.from_hcl` methods on the current class,
  # and a constructor which takes an `HCL::Block` and an `HCL::ExpressionContext`.
  # By default, these methods serialize into an HCL document containing the value of every tagged instance
  # variable, the keys being the instance variable name. Most primitives and collections supported as
  # instance variable values (string, integer, array, hash, etc.), along with objects which define `to_hcl`
  # and a constructor taking an `HCL::Block` and an `HCL::ExpressionContext`.
  # Union types are supported for attributes, including unions with nil. If multiple types in a union parse correctly,
  # it is undefined which one will be chosen. Union types are not supported for blocks.
  #
  # To denote an individual instance variables to be parsed and serialized, the annotation `HCL::Attribute`
  # must be placed on the instance variable. Annotating property, getter and setter macros is also allowed.
  # ```
  # require "json"
  #
  # class A
  #   include JSON::Serializable
  #
  #   @[HCL::Attribute(key: "my_key", emit_null: true)]
  #   getter a : Int32?
  # end
  # ```
  #
  # `HCL::Attribute` properties:
  # * **key**: the value of the key in the HCL document or block (by default the name of the instance variable)
  # * **converter**: specify an alternate type for parsing and generation. The converter must define `from_json(JSON::PullParser)` and `to_json(value, JSON::Builder)` as class methods. Examples of converters are `Time::Format` and `Time::EpochConverter` for `Time`.
  # * **presence**: if `true`, a `@{{key}}_present` instance variable will be generated when the key was present (even if it has a `null` value), `false` by default
  # * **emit_null**: if `true`, emits a `null` value for nilable property (by default nulls are not emitted)
  #
  # Deserialization also respects default values of variables:
  # ```
  # require "hcl"
  #
  # struct A
  #   include HCL::Serializable
  #   @a : Int64
  #   @b : Float64 = 1.0
  # end
  #
  # A.from_json(%<{"a":1}>) # => A(@a=1, @b=1.0)
  # ```
  #
  # ### Extensions: `JSON::Serializable::Strict` and `JSON::Serializable::Unmapped`.
  #
  # If the `HCL::Serializable::Strict` module is included, unknown properties in the HCL
  # document will raise a parse exception. By default the unknown properties
  # are silently ignored.
  # If the `HCL::Serializable::Unmapped` module is included, unknown properties in the HCL
  # document will be stored in a `Hash(String, HCL::Any)`. On serialization, any keys
  # inside hcl_unmapped_attributes, hcl_unmapped_blocks, and hcl_unmapped_labels
  # will be serialized and appended to the current HCL block or document.
  # ```
  # require "hcl"
  #
  # struct A
  #   include HCL::Serializable
  #   include HCL::Serializable::Unmapped
  #   @a : Int32
  # end
  #
  # a = A.from_json(%({"a":1,"b":2})) # => A(@json_unmapped={"b" => 2_i64}, @a=1)
  # a.to_json                         # => {"a":1,"b":2}
  # ```
  #
  #
  # ### Class annotation `HCL::Serializable::Options`
  #
  # supported properties:
  # * **emit_nulls**: if `true`, emits a `null` value for all nilable properties (by default nulls are not emitted)
  #
  # ```
  # require "json"
  #
  # @[HCL::Serializable::Options(emit_nulls: true)]
  # class A
  #   include HCL::Serializable
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
                nilable:     ivar.type.nilable?
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
              }
            %}
          {% elsif ann = ivar.annotation(::HCL::Label) %}
            {%
              labels[ivar.id] = {
                type:        ivar.type,
                index:       ann[:index] || current_label_idx,
                has_default: ivar.has_default_value?,
                default:     ivar.default_value,
                nilable:     ivar.type.nilable?
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
            @{{name}} = (%var{name}).as({{value[:type]}})
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
              %var{name} = {{value[:type]}}.new(block_node, __ctx_from_hcl)
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
                @{{name}} = %var{name}.as({{value[:type]}})
              {% end %}
            {% elsif value[:has_default] %}
              @{{name}} = %var{name}.nil? ? {{value[:default]}} : %var{name}.as({{value[:type]}})
            {% else %}
              @{{name}} = (%var{name}).as({{value[:type]}})
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

    protected def after_initialize
    end

    protected def on_unknown_hcl_attribute(node, key, ctx)
    end

    protected def on_unknown_hcl_block(node, key, ctx)
    end

    protected def on_unknown_hcl_label(node, idx, ctx)
    end

    protected def on_to_hcl(hcl)
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
      # Unmapped attributes
      property hcl_unmapped_attributes = Hash(String, ::HCL::Any).new

      # Unmapped blocks
      property hcl_unmapped_blocks = Hash(String, ::HCL::Any).new

      # Unmapped labels
      property hcl_unmapped_labels = Hash(Int32, ::HCL::Any).new

      protected def on_unknown_hcl_attribute(node, key, ctx)
        hcl_unmapped_attributes[key] = node.attributes[key].value(ctx)
      end

      protected def on_unknown_hcl_block(node, key, ctx)
        blocks = node.blocks.
          select { |block| block.id == key }.
          map { |block| block.value(ctx).dig(key) }

        if blocks.size == 1
          hcl_unmapped_blocks[key] = blocks.first
        else
          hcl_unmapped_blocks[key] = ::HCL::Any.new(blocks)
        end
      end

      protected def on_unknown_hcl_label(node, idx, ctx)
        hcl_unmapped_labels[idx] = node.labels[idx].value(ctx)
      end

      protected def on_to_hcl(hcl)
        # TODO: Translate to HCL
        # json_unmapped.each do |key, value|
        #   json.field(key) { value.to_json(json) }
        # end
      end
    end
  end
end
