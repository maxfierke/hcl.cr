module HCL
  module AST
    class Heredoc < Node
      getter :content, :delimiter, :indent_size

      def initialize(peg_tuple : Pegmatite::Token, source : String, delimiter : String, content : String)
        super(peg_tuple, source)
        @delimiter = delimiter

        if m = content.match(/^\s+/)
          @indent_size = m[0].size
          @content = content.gsub(/^\s{1,#{indent_size}}/m, "")
        else
          @content = content
          @indent_size = 0
        end
      end

      def string : String
        String.build do |heredoc|
          heredoc << "<<-"
          heredoc << delimiter
          heredoc << "\n"

          if indent_size > 0
            lines = content.split("\n")
            indent = " " * indent_size
            lines.each do |line|
              if line != ""
                heredoc << indent
                heredoc << line
                heredoc << "\n"
              end
            end

            delim_indent = " " * Math.max(1, indent_size - 2)
            heredoc << delim_indent
            heredoc << delimiter
          else
            heredoc << content
            heredoc << delimiter
          end

          heredoc << "\n"
        end
      end

      def value(ctx : ExpressionContext) : ValueType
        content
      end
    end
  end
end
