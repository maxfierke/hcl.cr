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
    end
  end
end
