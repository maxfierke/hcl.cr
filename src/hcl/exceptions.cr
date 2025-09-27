module HCL
  # Base error class for HCL parsing exceptions
  class ParseException < Exception
    @line_number : Int32?
    @path : Path?

    getter :line_number, :path

    # :nodoc:
    def initialize(message, source : String? = nil, token : Pegmatite::Token? = nil, offset : Int32? = nil, path : String? = nil)
      if token && source
        line_number = source[0...token[1]].count('\n') + 1
      elsif source && offset
        line_number = source[0...offset].count('\n') + 1
      end

      path = Path[path] if path

      message = String.build do |msg|
        msg << "Unable to parse HCL document"
        if source && token
          msg << " at or near '#{source[token[1]...token[2]]}'"
        end
        msg << ". Encountered "
        msg << message

        if path && line_number
          msg << " (#{path.normalize}:#{line_number})"
        elsif line_number
          msg << " (line #{line_number})"
        end

        if source && offset == source.size
          msg << "\nDid you forget to add a new line at the end?"
        end
      end

      @line_number = line_number
      @path = path

      super(message)
    end
  end

  # Raised when an invalid AST is attempted with `HCL::Builder`
  class BuildError < Exception; end

  # Base error class for expressions within HCL
  class ExpressionError < Exception; end

  # Base error class for function calls within HCL
  class CallError < ExpressionError; end

  # Raised when an undefined variable is referenced within HCL
  class VariableUndefinedError < ExpressionError; end

  # Raised when there is a mismatch in number of arguments passed to an HCL
  # function
  class ArityMismatchError < CallError; end

  # Raised when an undefined function is called within HCL
  class FunctionUndefinedError < CallError; end
end
