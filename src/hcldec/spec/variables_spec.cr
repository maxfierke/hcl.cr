module HCLDec
  class VariablesSpec < Spec
    include HCL::Serializable::Unmapped

    def attributes
      hcl_unmapped_attributes
    end

    def validate!
    end
  end
end
