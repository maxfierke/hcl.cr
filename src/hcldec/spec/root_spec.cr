module HCLDec
  class RootSpec < Spec
    include HCL::Serializable::Strict

    @[HCL::Block]
    property literal : LiteralSpec? = nil

    @[HCL::Block]
    property object : ObjectSpec? = nil

    @[HCL::Block(key: "block")]
    property blocks : Array(HCLDec::BlockSpec) = Array(HCLDec::BlockSpec).new

    @[HCL::Block(key: "block_list")]
    property block_lists : Array(HCLDec::BlockListSpec) = Array(HCLDec::BlockListSpec).new

    @[HCL::Block(key: "function")]
    property functions : Array(HCLDec::UserFuncSpec) = Array(HCLDec::UserFuncSpec).new

    @[HCL::Block]
    property variables : HCLDec::VariablesSpec? = nil

    def validate!
      found_blocks = 0
      found_blocks += 1 if literal
      found_blocks += 1 if object
      found_blocks += 1 if blocks.any?
      found_blocks += 1 if block_lists.any?

      if found_blocks == 0
        raise SpecViolation.new(
          "Missing spec block: A spec file must have exactly one root block specifying how to map to a JSON value."
        )
      elsif found_blocks > 1
        raise SpecViolation.new(
          "Extraneous spec block: A spec file must have exactly one root block specifying how to map to a JSON value."
        )
      end

      if lit = literal
        lit.validate!
      end

      if obj = object
        obj.validate!
      end

      blocks.each(&.validate!)
      block_lists.each(&.validate!)
      functions.each(&.validate!)

      if vars = variables
        vars.validate!
      end
    end
  end
end
