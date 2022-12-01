module HCLDec
  class AttrSpec < Spec
    @[HCL::Label]
    property block_name : String? = nil

    @[HCL::Attribute]
    property name : String? = nil

    @[HCL::Attribute]
    property type : String? = nil

    @[HCL::Attribute]
    property required = false

    def name
      @name || block_name || ""
    end

    def validate!
      if name.empty?
        raise SpecViolation.new(
          "Missing name in attribute spec: The name attribute is required, to specify the attribute name that is expected in an input HCL file."
        )
      end
    end
  end
end
