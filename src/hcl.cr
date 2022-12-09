require "big"
require "option_parser"
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
  VERSION = "0.2.1"

  def self.build(io : IO, &block)
    HCL::Builder.build do |builder|
      yield builder
    end.to_s(io)
  end

  def self.build(&block)
    String.build do |str|
      build(str) do |builder|
        yield builder
      end
    end
  end

  def self.parse(io)
    HCL::Parser.parse!(io)
  end
end
