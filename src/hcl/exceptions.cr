module HCL
  # Base error class for HCL parsing exceptions
  class ParseException < Exception
    getter filename : String
    getter line_start : Int32
    getter line_end : Int32
    getter start_offset : Int32
    getter end_offset : Int32

    def initialize(
      message,
      source : String? = nil,
      filename : String? = nil,
      match_error : Pegmatite::Pattern::MatchError? = nil,
      token : Pegmatite::Token? = nil
    )
      @filename = filename || ""

      # Line matching is cribbed from Pegmatite::Pattern::MatchError
      # TODO: Get this added to public API
      if match_error && source
        @start_offset = [match_error.offset - 1, 0].max
        @line_start = (source.rindex("\n", @start_offset) || -1) + 1
        @line_end = (source.index("\n", match_error.offset) || source.size)
        @end_offset = match_error.offset
      elsif token && source
        @line_start = (source.rindex("\n", [token[1] - 1, 0].max) || -1) + 1
        @line_end = (source.index("\n", token[2]) || source.size)
        @start_offset = token[1]
        @end_offset = token[2]
      else
        @line_start = 0_i32
        @line_end = 0_i32
        @start_offset = 0_i32
        @end_offset = 0_i32
      end

      start_char_offset = source ? source.byte_index_to_char_index(@start_offset) : nil
      finish_char_offset = source ? source.byte_index_to_char_index(@end_offset) : nil

      if source && start_char_offset && finish_char_offset
        super(<<-MSG.strip)
        #{message}. At or near '#{source[start_char_offset...finish_char_offset]}'
        MSG
      else
        super(message)
      end
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
