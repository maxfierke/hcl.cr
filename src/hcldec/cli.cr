module HCLDec
  class CLI
    property output_io : IO = STDOUT
    property spec_path = ""
    property vars : JSON::Any? = nil

    # TODO: Build time
    @version = "0.0.1"

    getter :output_io, :spec_path

    def self.run!(args)
      cli = new
      options = cli.parse(args)
      cli.run
    end

    def parse(args)
      OptionParser.parse(args) do |parser|
        parser.banner = "Usage: hcldec --spec=<spec-file> [options] [hcl-file ...]"
        parser.on("-o", "--out OUT", "Specify the output file, instead of stdout") do |out_file_path|
          out_file = File.new(File.expand_path(out_file_path), mode: "w")
          self.output_io = out_file

          at_exit { out_file.close }
        end
        parser.on("-s", "--spec SPEC", "Specify path to spec file") { |spec_path| self.spec_path = spec_path }
        parser.on("-V", "--vars JSON_OR_FILE", "Provide variables to the given configuration file(s)") do |vars|
          stripped_vars = vars.strip
          if stripped_vars.starts_with?('{')
            self.vars = JSON.parse(stripped_vars)
          elsif File.exists?(stripped_vars)
            file_contents = File.read(stripped_vars)
            self.vars = JSON.parse(file_contents)
          end
        end
        parser.on("-v", "--help", "Show this help") { puts parser }
        parser.on("-h", "--version", "Show the version number and immediately exit") do
          puts @version
          exit 0
        end
        parser.on("--diags FORMAT", "Unimplemented") { }
        parser.on("--var-refs", "Unimplemented") { }
        parser.on("--with-type", "Unimplemented") { }
        parser.on("--keep-nulls", "Unimplemented") { }
        parser.invalid_option do |flag|
          STDERR.puts "ERROR: #{flag} is not a valid option."
          STDERR.puts parser
          exit(1)
        end
      end
    end

    def run
      if spec_path.empty?
        STDERR.puts "Spec file must be provided with -s/--spec"
        exit 1
      elsif !File.exists?(spec_path)
        STDERR.puts "Spec file does not exist at '#{spec_path}'"
        exit 1
      end

      spec = load_spec_file(spec_path)
      spec.validate!

      hcl_doc = HCL.parse(ARGF.gets_to_end)

      if lit = spec.literal
        puts lit.value.to_json
      else
        puts hcl_doc.to_json(
          ctx: HCL::ExpressionContext.default_context
        )
      end
    rescue e : HCL::ParseException
      STDERR.puts e.to_json
      exit 1
    rescue e : HCLDec::SpecViolation
      STDERR.puts e.to_json
      exit 1
    end

    private def load_spec_file(spec_path)
      spec_doc = RootSpec.from_hcl(
        File.read(spec_path),
        ctx: hcl_spec_context
      )
    end

    private def hcl_spec_context
      ctx = HCL::ExpressionContext.default_context
      ctx.mode = HCL::ExpressionContext::Mode::LITERAL
      ctx.variables["any"] = HCL::Any.new(HCLDec::TYPE_ANY)
      ctx.variables["bool"] = HCL::Any.new(HCLDec::TYPE_BOOL)
      ctx.variables["number"] = HCL::Any.new(HCLDec::TYPE_NUMBER)
      ctx.variables["string"] = HCL::Any.new(HCLDec::TYPE_STRING)

      ctx.functions["list"] = HCLDec::Functions::List.new
      ctx.functions["map"] = HCLDec::Functions::Map.new

      ctx
    end
  end
end
