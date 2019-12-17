module HCL
  struct ValueType
    alias Types = Nil |
      Bool |
      String |
      Int64 |
      Float64 |
      Hash(String, Types) |
      Array(Types)

    # TODO: Figure out a way to do this in a less gross way
    TypeTuple = {
      Nil,
      Bool,
      String,
      Int64,
      Float64,
      Hash(String, ValueType),
      Array(ValueType)
    }

    @raw : Nil |
           Bool |
           String |
           Int64 |
           Float64 |
           Hash(String, ValueType) |
           Array(ValueType)

    getter :raw

    def initialize(@raw)
    end

    def dup
      new(raw.dup)
    end

    def clone
      new(raw.clone)
    end

    def unwrap : Types
      val = raw

      if val.is_a?(Array(ValueType))
        val.map(&.unwrap).as(Types)
      elsif val.is_a?(Hash(String, ValueType))
        val.transform_values do |val|
          val.unwrap.as(Types)
        end
      else
        val
      end
    end

    def self.new(pull : JSON::PullParser)
      hash = Hash(String, ValueType).new
      pull.read_object do |key, key_location|
        parsed_key = String.from_json_object_key?(key)
        unless parsed_key
          raise JSON::ParseException.new("Can't convert #{key.inspect} into #{ValueType}", *key_location)
        end
        hash[parsed_key] = new(pull)
      end
      ValueType.new(hash)
    end

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
            return ValueType.new(value) unless value.nil?
          {% else %}
            {% non_primitives << type %}
          {% end %}
        {% end %}

        # If after traversing all the types we are left with just one
        # non-primitive type, we can parse it directly (no need to use `read_raw`)
        {% if non_primitives.size == 1 %}
          return ValueType.new({{non_primitives[0]}}.new(pull))
        {% end %}
      {% end %}

      string = pull.read_raw
      {% for type in TypeTuple %}
        begin
          return ValueType.new({{type}}.from_json(string))
        rescue JSON::ParseException
          # Ignore
        end
      {% end %}
      raise JSON::ParseException.new("Couldn't parse #{self} from #{string}", *location)
    end

    def to_json(builder : JSON::Builder)
      raw.to_json(builder)
    end
  end
end
