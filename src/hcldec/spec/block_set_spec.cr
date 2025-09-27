module HCLDec
  class BlockSetSpec < Spec
    @[HCL::Label]
    property block_name : String? = nil

    @[HCL::Attribute]
    property block_type : String? = nil

    @[HCL::Block]
    property object : ObjectSpec

    def block_type
      @block_type || block_name || ""
    end

    def validate!
      if block_type.empty?
        raise SpecViolation.new(
          "Missing block_type in block_set spec: The block_type attribute is required, to specify the block type name that is expected in an input HCL file."
        )
      end
    end
  end
end
