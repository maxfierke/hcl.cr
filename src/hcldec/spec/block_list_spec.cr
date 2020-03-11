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

    def validate!
      if block_type.empty?
        raise "Missing block_type in block_list spec: The block_type attribute is required, to specify the block type name that is expected in an input HCL file."
      end
    end
  end
end
