module HCLDec
  class BlockListSpec < Spec
    @[HCL::Label]
    property block_name : String? = nil

    @[HCL::Attribute]
    property block_type : String? = nil

    @[HCL::Attribute]
    property min_items : Int64 = 0_i64

    @[HCL::Attribute]
    property max_items : Int64 = 0_i64

    @[HCL::Block]
    property attr : AttrSpec? = nil

    @[HCL::Block]
    property object : ObjectSpec? = nil

    def block_type
      @block_type || block_name || ""
    end
  end
end
