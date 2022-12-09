require "./hcl"
require "./hcldec/type_checking"
require "./hcldec/functions/*"
require "./hcldec/spec_violation"
require "./hcldec/spec"
require "./hcldec/spec/attr_spec"
require "./hcldec/spec/*"
require "./hcldec/json_writer"
require "./hcldec/cli"

HCLDec::CLI.run!(ARGV)
