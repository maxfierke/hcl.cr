require "pegmatite"
require "json"

require "./hcl/ast"
require "./hcl/ast/node"
require "./hcl/ast/body"
require "./hcl/ast/*"
require "./hcl/function"
require "./hcl/functions/*"
require "./hcl/visitor"
require "./hcl/visitors/*"
require "./hcl/*"

module HCL
  VERSION = "0.3.0"

  # Build a new HCL document using a DSL and output to the given `IO`
  def self.build(io : IO, &block)
    HCL::Builder.build do |builder|
      yield builder
    end.to_s(io)
  end

  # Build a new HCL document using a DSL and return as a `String`
  def self.build(&block)
    String.build do |str|
      build(str) do |builder|
        yield builder
      end
    end
  end
end
