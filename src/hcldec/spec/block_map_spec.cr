module HCLDec
  class BlockMapSpec < Spec
    @[HCL::Label]
    property block_name : String? = nil

    @[HCL::Attribute]
    property block_type : String? = nil

    @[HCL::Attribute]
    property labels : Array(String)

    @[HCL::Block]
    property object : ObjectSpec

    def block_type
      @block_type || block_name || ""
    end
  end
end
