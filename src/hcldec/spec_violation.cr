module HCLDec
  class SpecViolation < Exception
    def initialize(message)
      super(message)
    end

    def to_json
      {
        "diagnostics" => [
          {
            "severity" => "error",
            "summary"  => message,
          },
        ],
      }.to_json
    end
  end
end
