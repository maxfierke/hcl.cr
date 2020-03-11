module HCLDec
  class ArraySpec < Spec
    @[HCL::Label]
    property block_name : String? = nil

    @[HCL::Attribute]
    property block_type : String? = nil

    @[HCL::Block(key: "attr")]
    property attrs : Array(AttrSpec) = Array(AttrSpec).new

    def block_type
      @block_name || block_type || ""
    end
  end
end
