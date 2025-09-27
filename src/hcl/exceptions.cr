module HCL
  # Base error class for HCL parsing exceptions
  class ParseException < Exception
    getter line_number : Int32
    getter end_line_number : Int32
    getter start_offset : Int32
    getter end_offset : Int32
    getter path : Path?

    # :nodoc:
    def initialize(message, source : String? = nil, token : Pegmatite::Token? = nil, offset : Int32? = nil, path : String? = nil)
      # Line matching is cribbed from Pegmatite::Pattern::MatchError
      # TODO: Get this added to public API
      if offset && source
        @start_offset = [offset - 1, 0].max
        @line_number = (source.rindex("\n", @start_offset) || -1) + 1
        @end_line_number = (source.index("\n", offset) || source.size)
        @end_offset = offset
      elsif token && source
        @line_number = (source.rindex("\n", [token[1] - 1, 0].max) || -1) + 1
        @end_line_number = (source.index("\n", token[2]) || source.size)
        @start_offset = token[1]
        @end_offset = token[2]
      else
        @line_number = 0_i32
        @end_line_number = 0_i32
        @start_offset = 0_i32
        @end_offset = 0_i32
      end

      start_char_offset = source ? source.byte_index_to_char_index(@start_offset) : nil
      finish_char_offset = source ? source.byte_index_to_char_index(@end_offset) : nil

      path = Path[path] if path

      message = String.build do |msg|
        msg << "Unable to parse HCL document"
        if source && token
          msg << " at or near '#{start_char_offset...finish_char_offset}'"
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

      @path = path

      super(message)
    end

    def to_json
      {
        "diagnostics" => [
          {
            "severity" => "error",
            "summary"  => message,
            "subject"  => {
              "filename" => filename,
              "start"    => {
                "line" => line_start,
                "byte" => start_offset,
              },
              "end" => {
                "line" => line_end,
                "byte" => end_offset,
              },
            },
          },
        ],
      }.to_json
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
