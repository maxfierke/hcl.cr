module HCL
  class Token::Identifier < Token
    @parts : Nil | Array(Identifier)
    @string_parts : Nil | Array(::String)

    alias Value = NamedTuple(
      id: ::String,
      parts: Array(Value)
    )

    def value
      {
        id: string,
        parts: parts_value
      }
    end

    def includes_parts?
      string.includes?('.')
    end

    def string_parts
      @string_parts ||= string.split('.')
    end

    def parts
      @parts ||= string_parts.map do |part|
        # TODO: Figure out at the actual token start/end positions
        Identifier.new({:identifier, -1, -1}, part)
      end
    end

    private def parts_value
      if includes_parts?
        parts.map { |part| part.value.as(Value) }
      else
        [] of Value
      end
    end
  end
end
