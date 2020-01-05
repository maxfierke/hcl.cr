class Array
  def to_hcl(builder : HCL::Builder)
    builder.list do |l|
      each do |val|
        l << val.to_hcl(builder)
      end
    end
  end
end

struct Bool
  def to_hcl(builder : HCL::Builder)
    builder.literal(self.to_s)
  end
end

class Hash
  def to_hcl(builder : HCL::Builder)
    builder.map do |m|
      each do |key, value|
        m.attribute(key) { value.to_hcl(m) }
      end
    end
  end
end

struct NamedTuple
  def to_hcl(builder : HCL::Builder)
    builder.map do |m|
      {% for key in T.keys %}
        m.attribute({{key.symbolize}}) { self[{{key.symbolize}}].to_hcl(m) }
      {% end %}
    end
  end
end

struct Nil
  def to_hcl(builder : HCL::Builder)
    builder.literal("null")
  end
end

struct Number
  def to_hcl(builder : HCL::Builder)
    builder.number(self)
  end
end

struct Set
  def to_hcl(builder : HCL::Builder)
    builder.list do |l|
      each do |val|
        l << val.to_hcl(builder)
      end
    end
  end
end

class String
  def to_hcl(builder : HCL::Builder)
    builder.literal(self)
  end
end

struct Symbol
  def to_hcl(builder : HCL::Builder)
    builder.identifier(self)
  end
end

struct Tuple
  def to_hcl(builder : HCL::Builder)
    builder.list do |l|
      each do |val|
        l << val.to_hcl(builder)
      end
    end
  end
end
