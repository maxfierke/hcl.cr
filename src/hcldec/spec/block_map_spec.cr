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

    def validate!
      if block_type.empty?
        raise SpecViolation.new(
          "Missing block_type in block_map spec: The block_type attribute is required, to specify the block type name that is expected in an input HCL file."
        )
      elsif labels.size < 1
        raise SpecViolation.new(
          "Invalid block label name list: A block_map must have at least one label specified."
        )
      end
    end
  end
end
