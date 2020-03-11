module HCLDec
  class DefaultSpec < Spec
    include HCL::Serializable::Unmapped

    def blocks(ctx : HCL::ExpressionContext)
      hcl_unmapped_blocks.map do |block|
        Spec.new(body, ctx)
      end
    end
  end
end
