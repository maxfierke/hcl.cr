module HCLDec
  class RootSpec < Spec
    include HCL::Serializable::Strict

    @[HCL::Block]
    property literal : LiteralSpec? = nil

    @[HCL::Block]
    property object : ObjectSpec? = nil

    def validate!
      if !literal && !object
        raise SpecViolation.new(
          "Missing spec block: A spec file must have exactly one root block specifying how to map to a JSON value."
        )
      elsif literal && object
        raise SpecViolation.new(
          "Extraneous spec block: A spec file must have exactly one root block specifying how to map to a JSON value."
        )
      end
    end
  end
end
