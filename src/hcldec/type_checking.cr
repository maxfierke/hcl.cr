module HCLDec
  TYPE_PREFIX = "__$$hcl$$__$$typedef$$_"
  TYPE_ANY    = "#{TYPE_PREFIX}any"
  TYPE_BOOL   = "#{TYPE_PREFIX}bool"
  TYPE_NUMBER = "#{TYPE_PREFIX}number"
  TYPE_STRING = "#{TYPE_PREFIX}string"
  TYPES       = [TYPE_ANY, TYPE_BOOL, TYPE_NUMBER, TYPE_STRING]
end

module HCL
  struct Any
    def to_json(builder : JSON::Builder)
      r = raw
      if r.is_a?(String) && r.starts_with?(::HCLDec::TYPE_PREFIX)
        r.lstrip(::HCLDec::TYPE_PREFIX).to_json(builder)
      elsif r.is_a?(BigDecimal)
        # BigDecimal doesn't implement #to_json(builder : JSON::Builder) :(
        builder.raw r.to_s
      else
        r.to_json(builder)
      end
    end

    def to_s(io : IO) : Nil
      if (r = as_s?) && r.starts_with?(::HCLDec::TYPE_PREFIX)
        r.lstrip(::HCLDec::TYPE_PREFIX).to_s(io)
      else
        raw.to_s(io)
      end
    end
  end
end
