module HCL
  module AST
    class ValueRefToken < ValueToken
      @id : String
      @index : Nil | Int64 | String
      @parts : Nil | Array(ValueRefToken)
      @string_parts : Array(String)

      alias Value = NamedTuple(
        id: String,
        index: Nil | Int64 | String,
        path: String,
        parts: Array(Value)
      )

      getter :id, :index

      def initialize(peg_tuple : Pegmatite::Token, string : String)
        super(peg_tuple, string)

        @string_parts = string.split('.')
        id = @string_parts.last

        if index_match = id.match(/([^\[]*)\[([^\]]*)\]/)
          @id = index_match[1]
          @index = index_match[2]
        else
          @id = id
          @index = nil
        end
      end

      def value
        {
          id: id,
          index: index,
          path: string,
          parts: parts_value
        }
      end

      def parts
        @parts ||= begin
          last_finish = src_start

          @string_parts.map do |part|
            new_finish = last_finish + part.bytesize
            token = ValueRefToken.new({:value_ref, last_finish, new_finish}, part)
            last_finish = new_finish

            token
          end
        end
      end

      private def parts_value
        if string.includes?('.')
          parts.map { |part| part.value.as(Value) }
        else
          [] of Value
        end
      end
    end
  end
end
