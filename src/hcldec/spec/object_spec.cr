module HCLDec
  class ObjectSpec < Spec
    @[HCL::Block(key: "attr")]
    property attrs : Array(HCLDec::AttrSpec) = Array(HCLDec::AttrSpec).new

    @[HCL::Block(key: "block")]
    property blocks : Array(HCLDec::BlockSpec) = Array(HCLDec::BlockSpec).new

    @[HCL::Block(key: "block_list")]
    property block_lists : Array(HCLDec::BlockListSpec) = Array(HCLDec::BlockListSpec).new

    @[HCL::Block(key: "function")]
    property functions : Array(HCLDec::UserFuncSpec) = Array(HCLDec::UserFuncSpec).new

    @[HCL::Block]
    property variables : HCLDec::VariablesSpec? = nil

    def validate!
      attrs.each(&.validate!)
      blocks.each(&.validate!)
      block_lists.each(&.validate!)
      functions.each(&.validate!)
      if vars = variables
        vars.validate!
      end
    end
  end
end
