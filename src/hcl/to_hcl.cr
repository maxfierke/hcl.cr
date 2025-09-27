class Array
  # Returns HCL list representation of `Array`
  def to_hcl(builder : HCL::Builder)
    builder.list do |l|
      each do |val|
        l << val.to_hcl(builder)
      end
    end
  end
end

struct Bool
  # Returns HCL boolean literal
  def to_hcl(builder : HCL::Builder)
    builder.literal(self.to_s)
  end
end

class Hash
  # Returns HCL map representation of `Hash`
  def to_hcl(builder : HCL::Builder)
    builder.map do |m|
      each do |key, value|
        m.attribute(key) { value.to_hcl(m) }
      end
    end
  end
end

struct NamedTuple
  # Returns HCL map representation of `NamedTuple`
  def to_hcl(builder : HCL::Builder)
    builder.map do |m|
      {% for key in T.keys %}
        m.attribute({{key.symbolize}}) { self[{{key.symbolize}}].to_hcl(m) }
      {% end %}
    end
  end
end

struct Nil
  # Returns HCL null
  def to_hcl(builder : HCL::Builder)
    builder.literal("null")
  end
end

struct Number
  # Returns HCL number literal
  def to_hcl(builder : HCL::Builder)
    builder.number(self)
  end
end

struct Set
  # Returns HCL list representation of `Set`
  def to_hcl(builder : HCL::Builder)
    builder.list do |l|
      each do |val|
        l << val.to_hcl(builder)
      end
    end
  end
end

class String
  # Returns HCL string literal
  def to_hcl(builder : HCL::Builder)
    builder.literal(self)
  end
end

struct Symbol
  # Returns HCL string literal for symbol
  def to_hcl(builder : HCL::Builder)
    builder.identifier(self)
  end
end

struct Tuple
  # Returns HCL list representation of `Tuple`
  def to_hcl(builder : HCL::Builder)
    builder.list do |l|
      each do |val|
        l << val.to_hcl(builder)
      end
    end
  end
end
