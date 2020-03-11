module HCLDec
  abstract class Spec
    include HCL::Serializable

    def self.new(node : ::HCL::AST::Body, ctx : ::HCL::ExpressionContext)
      if node.is_a?(::HCL::AST::Block)
        klass = case node.id
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
        when "variable"
          VariableSpec
        else
          raise "Invalid spec block: Blocks of type '#{block_node.id}' are not expected here."
        end

        klass.new(node, ctx)
      else
        super
      end
    end
  end
end
