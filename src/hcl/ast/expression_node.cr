module HCL
  module AST
    class ExpressionNode < Node
      getter :children, :context

      def initialize(
        peg_tuple : Pegmatite::Token,
        source : String,
        children : Array(Node),
        context : ExpressionContext
      )
        super(peg_tuple, source)

        @children = children
        @context = context
      end

      def string : String
        children.map do |exp|
          case exp
          when ExpressionNode
            "(#{exp.string})"
          else
            exp.string
          end
        end.join("")
      end

      def value : ValueType
        # TODO: This is wrong.
        result : ValueType = nil
        children.reduce(result) do |result, child|
          if child.is_a?(GetAttrNode)
            if result && result.is_a?(Hash(String, ValueType))
              attr = result[child.attribute_name]
              result = attr
            else
              raise "Cannot read attribute #{child.attribute_name} from #{typeof(result)}"
            end
          elsif child.is_a?(IndexNode)
            child_val = child.index_exp.value

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
            result = child.value
          else
            raise "BUG: Cannot evaluate token #{child.class}"
          end

          result
        end
      end
    end
  end
end
