module HCLDec
  abstract class Spec
    include HCL::Serializable

    def self.new_spec_from_block_node(block : ::HCL::AST::Block, ctx : ::HCL::ExpressionContext)
      klass = case block.id
              when "array"
                ArraySpec
              when "attr"
                AttrSpec
              when "block_attrs"
                BlockAttrsSpec
              when "block_list"
                BlockListSpec
              when "block_map"
                BlockMapSpec
              when "block_set"
                BlockSetSpec
              when "block"
                BlockSpec
              when "default"
                DefaultSpec
              when "literal"
                LiteralSpec
              when "object"
                ObjectSpec
              when "function"
                UserFuncSpec
              when "variables"
                VariablesSpec
              else
                raise "Invalid spec block: Blocks of type '#{block.id}' are not expected here."
              end

      klass.new(block, ctx)
    end

    abstract def validate!
  end
end
