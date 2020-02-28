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

      def to_s(io : IO)
        io << "<<-"
        io << delimiter
        io << "\n"

        if indent_size > 0
          lines = content.to_s.split("\n")
          indent = " " * Math.max(2, indent_size - 2)
          lines.each do |line|
            if line != ""
              io << indent
              io << line
              io << "\n"
            end
          end

          delim_indent = " " * Math.max(0, indent_size - 4)
          io << delim_indent
          io << delimiter
        else
          io << content
          io << delimiter
        end
      end

      def value(ctx : ExpressionContext) : Any
        content.value(ctx)
      end
    end
  end
end
