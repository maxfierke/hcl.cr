module HCLDec
  # Defines a user function within a spec document.
  class UserFuncSpec < Spec
    @[HCL::Label]
    property name : String

    @[HCL::Attribute]
    property params : HCL::AST::Expression

    @[HCL::Attribute]
    property variadic_param : HCL::AST::Expression? = nil

    @[HCL::Attribute]
    property result : HCL::AST::Expression
  end
end
