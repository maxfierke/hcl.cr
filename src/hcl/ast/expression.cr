module HCL
  module AST
    class Expression < Node
      getter :children

      def initialize(
        peg_tuple : Pegmatite::Token,
        source : String,
        children : Array(Node)
      )
        super(peg_tuple, source)

        @children = children
      end

      def to_s(io : IO)
        children.each do |exp|
          case exp
          when Expression
            io << "("
            exp.to_s(io)
            io << ")"
          else
            exp.to_s(io)
          end
        end
      end

      def value(ctx : ExpressionContext) : ValueType
        children.reduce(HCL::ValueType.new(nil)) do |result, child|
          current = result ? result.raw : nil
          next_val = nil
          if child.is_a?(GetAttrExpr)
            if current && current.is_a?(Hash(String, ValueType))
              # TODO: Handle splat
              attr = current[child.attribute_name].raw
              next_val = attr
            else
              raise "Cannot read attribute #{child.attribute_name} from #{typeof(current)}"
            end
          elsif child.is_a?(IndexExpr)
            child_val = child.index_exp.value(ctx).raw

            if child_val.is_a?(String) && current && current.is_a?(Hash(String, ValueType))
              # TODO: Handle splat
              attr = current[child_val].raw
              next_val = attr
            elsif child_val.is_a?(Int64) && current && current.is_a?(Array(ValueType))
              attr = current[child_val].raw
              next_val = attr
            else
              raise "Cannot read member #{child_val} from #{typeof(current)}"
            end
          else
            next_val = child.value(ctx).raw
          end

          HCL::ValueType.new(next_val)
        end
      end
    end
  end
end
