module HCL
  module AST
    class Heredoc < Node
      getter :content, :delimiter, :indent_size

      def initialize(delimiter : String, content : Template, **kwargs)
        super(**kwargs)
        @delimiter = delimiter
        @content = content

        if m = content.source.match(/^\s+/)
          @indent_size = m[0].size
        else
          @indent_size = 0
        end
      end

      def as_json(ctx : ExpressionContext)
        json_heredoc = String.build do |str|
          if indent_size > 0
            lines = content.to_s.split("\n")
            indent = " " * Math.max(2, indent_size - 2)
            lines.each do |line|
              if line != ""
                str << indent
                str << line
                str << "\\n"
              end
            end
          else
            str << content
          end
        end

        Any.new(json_heredoc)
      end
    end
  end
end
