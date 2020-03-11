module HCLDec
  class LiteralSpec < Spec
    @[HCL::Attribute]
    property value : HCL::Any

    def validate!
    end
  end
end
