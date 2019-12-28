def Object.from_hcl(string_or_io : String | IO, ctx : HCL::ExpressionContext = HCL::ExpressionContext.default_context)
  document = HCL::Parser.parse!(string_or_io)
  new(document, ctx)
end
