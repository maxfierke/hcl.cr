module HCLDec
  class DefaultSpec < Spec
    include HCL::Serializable::Unmapped

    def blocks(ctx : HCL::ExpressionContext)
      hcl_unmapped_blocks.map do |block|
        Spec.new(body, ctx)
      end
    end

    def validate!
      if hcl_unmapped_blocks.empty?
        raise "Missing spec block: A default block must have at least one nested spec, each specifying a possible outcome."
      elsif hcl_unmapped_blocks.size == 1
        # TODO: Log a warning or something about this being a useless default block.
        # Useless default block: A default block with only one spec is equivalent to using that spec alone.
      end
    end
  end
end
