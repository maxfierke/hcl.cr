module HCL
  module AST
    class Expression < Node
      getter :children

      def initialize(children : Array(Node), **kwargs)
        super(**kwargs)
        @children = children
      end

      def value(ctx : ExpressionContext) : Any
        children.reduce(HCL::Any.new(nil)) do |result, child|
          current = result ? result.raw : nil
          next_val = nil
          if child.is_a?(GetAttrExpr)
            if !current
              raise "Cannot read attribute #{child.attribute_name} from null"
            elsif current.is_a?(Hash(String, Any))
              attr = current[child.attribute_name].raw
              next_val = attr
            elsif current.is_a?(Array(Any))
              # Handles splat
              next_val = current.map { |item| item[child.attribute_name] }
            else
              raise "Cannot read attribute #{child.attribute_name} from #{current.class}"
            end
          elsif child.is_a?(IndexExpr)
            child_val = child.index_exp.value(ctx).raw

            if !current
              raise "Cannot read member #{child_val} from null"
            elsif child_val.is_a?(String) && current.is_a?(Hash(String, Any))
              attr = current[child_val].raw
              next_val = attr
            elsif child_val.is_a?(Int64) && current.is_a?(Array(Any))
              attr = current[child_val].raw
              next_val = attr
            else
              raise "Cannot read member #{child_val} from #{current.class}"
            end
          elsif child.is_a?(SplatExpr)
            if !current
              raise "Cannot perform splat on null"
            elsif current.is_a?(Array(Any))
              attr = current
              next_val = attr
            else
              raise "Cannot perform splat on #{current.class}"
            end
          else
            next_val = child.value(ctx).raw
          end

          HCL::Any.new(next_val)
        end
      end
    end
  end
end
