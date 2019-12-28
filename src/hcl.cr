require "pegmatite"
require "json"

module HCL
  VERSION = "0.1.0"
end

require "./hcl/ast"
require "./hcl/ast/node"
require "./hcl/ast/body"
require "./hcl/ast/*"
require "./hcl/function"
require "./hcl/functions/*"
require "./hcl/*"
