module HCL
  struct Any
    alias Type = Nil |
                 Bool |
                 String |
                 Int64 |
                 Float64 |
                 Hash(String, Any) |
                 Array(Any)
    alias RawType = Nil |
                    Bool |
                    String |
                    Int64 |
                    Float64 |
                    Hash(String, RawType) |
                    Array(RawType)

    @raw : Type

    getter :raw

    def initialize(hsh : Hash(String, RawType))
      @raw = hsh.transform_values { |val| HCL::Any.new(val) }
    end

    def initialize(array : Array(RawType))
      @raw = array.map { |item| HCL::Any.new(item) }
    end

    def initialize(@raw)
    end

    def unwrap : RawType
      val = raw

      if val.is_a?(Array(Any))
        val.map(&.unwrap).as(RawType)
      elsif val.is_a?(Hash(String, Any))
        val.transform_values do |val|
          val.unwrap.as(RawType)
        end
      else
        val
      end
    end

    # Assumes the underlying value is an `Array` or `Hash` and returns its size.
    # Raises if the underlying value is not an `Array` or `Hash`.
    def size : Int
      case object = @raw
      when Array
        object.size
      when Hash
        object.size
      else
        raise "Expected Array or Hash for #size, not #{object.class}"
      end
    end

    # Assumes the underlying value is an `Array` and returns the element
    # at the given index.
    # Raises if the underlying value is not an `Array`.
    def [](index : Int) : HCL::Any
      case object = @raw
      when Array
        object[index]
      else
        raise "Expected Array for #[](index : Int), not #{object.class}"
      end
    end

    # Assumes the underlying value is an `Array` and returns the element
    # at the given index, or `nil` if out of bounds.
    # Raises if the underlying value is not an `Array`.
    def []?(index : Int) : HCL::Any?
      case object = @raw
      when Array
        object[index]?
      else
        raise "Expected Array for #[]?(index : Int), not #{object.class}"
      end
    end

    # Assumes the underlying value is a `Hash` and returns the element
    # with the given key.
    # Raises if the underlying value is not a `Hash`.
    def [](key : String) : HCL::Any
      case object = @raw
      when Hash
        object[key]
      else
        raise "Expected Hash for #[](key : String), not #{object.class}"
      end
    end

    # Assumes the underlying value is a `Hash` and returns the element
    # with the given key, or `nil` if the key is not present.
    # Raises if the underlying value is not a `Hash`.
    def []?(key : String) : HCL::Any?
      case object = @raw
      when Hash
        object[key]?
      else
        raise "Expected Hash for #[]?(key : String), not #{object.class}"
      end
    end

    # Traverses the depth of a structure and returns the value.
    # Returns `nil` if not found.
    def dig?(key : String | Int, *subkeys)
      if value = self[key]?
        value.dig?(*subkeys)
      end
    end

    # :nodoc:
    def dig?(key : String | Int)
      case @raw
      when Hash, Array
        self[key]?
      end
    end

    # Traverses the depth of a structure and returns the value, otherwise raises.
    def dig(key : String | Int, *subkeys)
      if (value = self[key]) && value.responds_to?(:dig)
        return value.dig(*subkeys)
      end
      raise "HCL::Any value not diggable for key: #{key.inspect}"
    end

    # :nodoc:
    def dig(key : String | Int)
      self[key]
    end

    # Checks that the underlying value is `Nil`, and returns `nil`.
    # Raises otherwise.
    def as_nil : Nil
      @raw.as(Nil)
    end

    # Checks that the underlying value is `Bool`, and returns its value.
    # Raises otherwise.
    def as_bool : Bool
      @raw.as(Bool)
    end

    # Checks that the underlying value is `Bool`, and returns its value.
    # Returns `nil` otherwise.
    def as_bool? : Bool?
      as_bool if @raw.is_a?(Bool)
    end

    # Checks that the underlying value is `Int`, and returns its value as an `Int64`.
    # Raises otherwise.
    def as_i : Int64
      @raw.as(Int).to_i64
    end

    # Checks that the underlying value is `Int`, and returns its value as an `Int64`.
    # Returns `nil` otherwise.
    def as_i? : Int64?
      as_i if @raw.is_a?(Int64)
    end

    # Checks that the underlying value is `Float`, and returns its value as an `Float64`.
    # Raises otherwise.
    def as_f : Float64
      @raw.as(Float64)
    end

    # Checks that the underlying value is `Float`, and returns its value as an `Float64`.
    # Returns `nil` otherwise.
    def as_f? : Float64?
      @raw.as?(Float64)
    end

    # Checks that the underlying value is `String`, and returns its value.
    # Raises otherwise.
    def as_s : String
      @raw.as(String)
    end

    # Checks that the underlying value is `String`, and returns its value.
    # Returns `nil` otherwise.
    def as_s? : String?
      as_s if @raw.is_a?(String)
    end

    # Checks that the underlying value is `Array`, and returns its value.
    # Raises otherwise.
    def as_a : Array(Any)
      @raw.as(Array)
    end

    # Checks that the underlying value is `Array`, and returns its value.
    # Returns `nil` otherwise.
    def as_a? : Array(Any)?
      as_a if @raw.is_a?(Array)
    end

    # Checks that the underlying value is `Hash`, and returns its value.
    # Raises otherwise.
    def as_h : Hash(String, Any)
      @raw.as(Hash)
    end

    # Checks that the underlying value is `Hash`, and returns its value.
    # Returns `nil` otherwise.
    def as_h? : Hash(String, Any)?
      as_h if @raw.is_a?(Hash)
    end

    def hcl_type
      get_hcl_type(raw)
    end

    # Reads a `HCL::Any` value from the given pull parser.
    #
    # Based on https://github.com/crystal-lang/crystal/blob/6952aacb37682558d1a976b4ebf1b1456d9f8b84/src/json/any.cr#L23
    def self.new(pull : JSON::PullParser)
      case pull.kind
      when .null?
        new(pull.read_null)
      when .bool?
        new(pull.read_bool)
      when .int?
        new(pull.read_int)
      when .float?
        new(pull.read_float)
      when .string?
        new(pull.read_string)
      when .begin_array?
        ary = [] of HCL::Any
        pull.read_array do
          ary << new(pull)
        end
        new(ary)
      when .begin_object?
        hash = {} of String => HCL::Any
        pull.read_object do |key|
          hash[key] = new(pull)
        end
        new(hash)
      else
        raise "Unknown pull kind: #{pull.kind}"
      end
    end

    def to_hcl(builder : HCL::Builder)
      raw.to_hcl(builder)
    end

    # :nodoc:
    def to_json(builder : JSON::Builder)
      raw.to_json(builder)
    end

    # :nodoc:
    def inspect(io : IO) : Nil
      @raw.inspect(io)
    end

    # :nodoc:
    def to_s(io : IO) : Nil
      @raw.to_s(io)
    end

    # :nodoc:
    def pretty_print(pp)
      @raw.pretty_print(pp)
    end

    # Returns `true` if both `self` and *other*'s raw object are equal.
    def ==(other : Any)
      raw == other.raw
    end

    # Returns `true` if the raw object is equal to *other*.
    def ==(other)
      raw == other
    end

    # See `Object#hash(hasher)`
    def_hash raw

    # Returns a new HCL::Any instance with the `raw` value `dup`ed.
    def dup
      Any.new(raw.dup)
    end

    # Returns a new HCL::Any instance with the `raw` value `clone`ed.
    def clone
      Any.new(raw.clone)
    end

    private def get_hcl_type(obj)
      case obj
      when Any
        obj.hcl_type
      when Array
        types = obj.map { |e| get_hcl_type(e) }
        uniq_types = types.uniq
        if uniq_types.size > 1
          "tuple([#{types.join(", ")}])"
        elsif uniq_types.size == 1
          "list(#{uniq_types.first})"
        else
          "list(any)"
        end
      when Bool
        "bool"
      when String
        "string"
      when Int64, Float64
        "number"
      when Hash
        type_map = obj.map { |key, value| [key, get_hcl_type(value)] }.to_h
        uniq_types = type_map.values.uniq
        if uniq_types.size > 1
          attr_map = type_map.map do |item|
            attr, type = item
            "#{attr} = #{type}"
          end
          "object({ #{attr_map.join(", ")} })"
        elsif uniq_types.size == 1
          "map(#{uniq_types.first})"
        else
          "object(any)"
        end
      else
        "any"
      end
    end
  end
end

class Object
  def ===(other : HCL::Any)
    self === other.raw
  end
end

struct Value
  def ==(other : HCL::Any)
    self == other.raw
  end
end

class Reference
  def ==(other : HCL::Any)
    self == other.raw
  end
end

class Array
  def ==(other : HCL::Any)
    self == other.raw
  end
end

class Hash
  def ==(other : HCL::Any)
    self == other.raw
  end
end
