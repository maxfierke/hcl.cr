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

    # :nodoc:
    # TODO: Figure out a way to do this in a less gross way
    TypeTuple = {
      Nil,
      Bool,
      String,
      Int64,
      Float64,
      Hash(String, Any),
      Array(Any)
    }

    @raw : Type

    getter :raw

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
      if (value = self[key]?) && value.responds_to?(:dig?)
        value.dig?(*subkeys)
      end
    end

    # :nodoc:
    def dig?(key : String | Int)
      self[key]?
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

    # Reads a `HCL::Any` value from the given pull parser.
    #
    # Based on https://github.com/crystal-lang/crystal/blob/6952aacb37682558d1a976b4ebf1b1456d9f8b84/src/json/from_json.cr#L226
    def self.new(pull : JSON::PullParser)
      location = pull.location

      # Optimization: use fast path for primitive types
      {% begin %}
        # Here we store types that are not primitive types
        {% non_primitives = [] of Nil %}

        {% for type, index in TypeTuple %}
          {% if type == Nil %}
            return pull.read_null if pull.kind.null?
          {% elsif type == Bool || type == Int64 || type == Float64 || type == String %}
            value = pull.read?({{type}})
            return Any.new(value) unless value.nil?
          {% else %}
            {% non_primitives << type %}
          {% end %}
        {% end %}

        # If after traversing all the types we are left with just one
        # non-primitive type, we can parse it directly (no need to use `read_raw`)
        {% if non_primitives.size == 1 %}
          return Any.new({{non_primitives[0]}}.new(pull))
        {% end %}
      {% end %}

      string = pull.read_raw
      {% for type in TypeTuple %}
        begin
          return Any.new({{type}}.from_json(string))
        rescue JSON::ParseException
          # Ignore
        end
      {% end %}
      raise JSON::ParseException.new("Couldn't parse #{self} from #{string}", *location)
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
