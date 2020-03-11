module HCLDec
  class BlockAttrsSpec < Spec
    @[HCL::Label]
    property block_name : String? = nil

    @[HCL::Attribute]
    property block_type : String? = nil

    @[HCL::Attribute]
    property element_type : String

    @[HCL::Attribute]
    property required = false

    def block_type
      @block_type || block_name || ""
    end
  end
end
