module HCL
  module AST
    class Heredoc < Node
      getter :content, :delimiter, :indent_size

      def initialize(delimiter : String, content : String, **kwargs)
        super(**kwargs)
        @delimiter = delimiter

        if m = content.match(/^\s+/)
          @indent_size = m[0].size
          @content = content.gsub(/^\s{1,#{indent_size}}/m, "")
        else
          @content = content
          @indent_size = 0
        end
      end

      def to_s(io : IO)
        io << "<<-"
        io << delimiter
        io << "\n"

        if indent_size > 0
          lines = content.split("\n")
          indent = " " * indent_size
          lines.each do |line|
            if line != ""
              io << indent
              io << line
              io << "\n"
            end
          end

          delim_indent = " " * Math.max(1, indent_size - 2)
          io << delim_indent
          io << delimiter
        else
          io << content
          io << delimiter
        end
      end

      def value(ctx : ExpressionContext) : Any
        Any.new(content)
      end
    end
  end
end
