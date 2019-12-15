module HCL
  struct ValueType
    alias Types = Nil |
      Bool |
      String |
      Int64 |
      Float64 |
      Hash(String, Types) |
      Array(Types)

    @value : Nil |
             Bool |
             String |
             Int64 |
             Float64 |
             Hash(String, ValueType) |
             Array(ValueType)

    getter :value

    def initialize(@value)
    end

    def unwrap : Types
      val = value

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

    def to_json(builder : JSON::Builder)
      value.to_json(builder)
    end
  end
end
