# hcl.cr

A general-purpose HCL2 parser written in Crystal. Does not make any domain assumptions.
Aims to supports the standard HCL2 types and map to the HCL2 informational model.

HCL2 support is considered feature complete. However, it does not yet run against
the spec test suite, so there may be situations in which some documents do not
work as they should. Please report any issues [here](https://github.com/maxfierke/hcl.cr/issues/new).

## Aims

`hcl.cr` has the following goals, in order of importance:

1. Correctly implement the HCL2 spec
2. Be compatible with [the Go implementation](https://github.com/Hashicorp/hcl/tree/hcl2)
3. Easy to work with
4. Reasonably performant and efficient

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     hcl:
       github: maxfierke/hcl.cr
       version: ~> 0.2.2
   ```

2. Run `shards install`

## Usage

### Schema-based parsing

For most use-cases, schema-based parsing will be the easiest to work with.
`hcl.cr` provides an `HCL::Serializable` module, which can be used much like
`JSON::Serializable` and `YAML::Serializable` from the Crystal standard library.

The module allows you to define mappings for attributes, blocks, and labels on
your own classes and structs, and provides convienent `self.from_hcl` and `to_hcl`
methods.

See documentation on [`HCL::Serializable`](src/hcl/serializable.cr) for more information.

### Using the AST directly

For more advanced use cases, you can use the `HCL::Parser` class and work
with the AST nodes directly. `HCL::Builder` can also be used to build HCL ASTs
using a DSL, and create arbitrary HCL documents.

```crystal
require "hcl"

SRC_TEXT = <<-HEREDOC
# An AMI
variable "ami" {
  description = "the AMI to use"
}

/* A multi
  line comment. */
resource "aws_instance" "web" {
  ami               = "${var.ami}"
  count             = 2
  source_dest_check = false
  another_boolean = "true"
  something_i_want_default = null

  connection {
    user = "root"
  }
}
HEREDOC

parser = HCL::Parser.new(SRC_TEXT) # Parser object.

document = parser.parse! # Returns an HCL::AST::Document
value = document.evaluate   # Returns the HCL structure as Crystal data types
string = document.to_s # Returns string reconstruction of HCL configuration
```

## TODO

- [X] Add support for literals (numbers, strings, booleans, null)
- [X] Add support for blocks
- [X] Add support for identifer parsing
- [X] Add support for lists
- [X] Add support for maps/objects
- [X] Add support for function parsing, including varadic arguments
- [X] Add support for square-bracket attribute & index access on maps & lists
- [X] Add support for arithmetic and logic operators
- [X] Add support for conditional expressions
- [X] Add support for top-level attributes
- [X] Add support for identifier/variable evaluation
- [X] Add support for function evaluation
- [X] Add support for heredocs
- [X] Add standard functions
- [X] Add support for partial- and full-schema decoding and encoding of HCL documents
- [X] Add support for splats
- [X] Add support for parsing interpolations/templates
- [X] Add support for evaluating interpolations/templates
- [X] Add support for `for` expressions
- [X] Add support for template directives
- [ ] Spec compliance
- [ ] Run against HCL2 test suite
- [ ] More validations, better parse/eval errors

## Contributing

1. Fork it (<https://github.com/maxfierke/hcl.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

Licensed under The MIT License. See [LICENSE](LICENSE) for more information.

## Contributors

- [Max Fierke](https://github.com/maxfierke) - creator and maintainer
