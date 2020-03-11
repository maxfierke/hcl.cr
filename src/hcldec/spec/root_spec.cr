module HCLDec
  class RootSpec < Spec
    include HCL::Serializable::Strict

    @[HCL::Block]
    property literal : LiteralSpec? = nil

    @[HCL::Block]
    property object : ObjectSpec? = nil
  end
end
