module HCLDec
  class JsonWriter
    getter ctx : ::HCL::ExpressionContext
    getter doc : ::HCL::AST::Document
    getter spec : ::HCLDec::RootSpec

    def initialize(
      doc : ::HCL::AST::Document,
      spec : ::HCLDec::RootSpec,
      ctx : ::HCL::ExpressionContext,
    )
      @doc = doc
      @spec = spec
      @ctx = ctx
    end

    def to_json(io : IO)
      if lit = spec.literal
        io.puts lit.value.to_json
      else
        # TODO: this isn't correct as it ignores the spec file
        # but does gets us ~80% of the way there
        io.puts doc.to_json(
          ctx: ctx
        )
      end
    end
  end
end
