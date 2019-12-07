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
        # TODO: This is wrong.
        result : ValueType = nil
        children.reduce(result) do |result, child|
          if child.is_a?(GetAttrExpr)
            if result && result.is_a?(Hash(String, ValueType))
              attr = result[child.attribute_name]
              result = attr
            else
              raise "Cannot read attribute #{child.attribute_name} from #{typeof(result)}"
            end
          elsif child.is_a?(IndexExpr)
            child_val = child.index_exp.value(ctx)

            if child_val.is_a?(String) && result && result.is_a?(Hash(String, ValueType))
              attr = result[child_val]
              result = attr
            elsif child_val.is_a?(Int64) && result && result.is_a?(Array(ValueType))
              attr = result[child_val]
              result = attr
            else
              raise "Cannot read member #{child_val} from #{typeof(result)}"
            end
          elsif child.is_a?(Node)
            result = child.value(ctx)
          else
            raise "BUG: Cannot evaluate token #{child.class}"
          end

          result
        end
      end
    end
  end
end
