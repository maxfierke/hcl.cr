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
  end
end
