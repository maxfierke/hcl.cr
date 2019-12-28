module HCL
  # Base error class for HCL parsing exceptions
  class ParseException < Exception
    def initialize(message, source : String? = nil, token : Pegmatite::Token? = nil)
      if source && token
        super(<<-MSG.strip)
        #{message}. At or near '#{source[token[1]...token[2]]}'
        MSG
      else
        super(message)
      end
    end
  end

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
