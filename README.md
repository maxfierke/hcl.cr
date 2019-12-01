# hcl.cr

A general-purpose HCL2 parser written in Crystal. Does not make any domain assumptions.
Aims to supports the standard HCL2 types and map to the HCL2 informational model.

This is considered a work-in-progress, though may work already for simple HCL2
documents that don't depend on any dynamic evaluation (function calls, variables, interpolation)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     hcl:
       github: maxfierke/hcl.cr
   ```

2. Run `shards install`

## Usage

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

parser = HCL::Parser.new(SRC_TEXT) # Parser object. Is also an Iterator of tokens.

document = parser.parse! # Returns an HCL::AST::Document
value = document.value   # Returns the HCL structure as Crystal data types
string = document.string # Returns string reconstruction of HCL configuration
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## TODO

- [X] Add support for literals (numbers, strings, booleans, null)
- [X] Add support for blocks
- [X] Add support for identifer parsing
- [X] Add support for lists
- [X] Add support for maps/objects
- [X] Add support for function parsing
- [X] Add support for square-bracket attribute & index access on maps & lists
- [X] Add support for arithmetic and logic operators
- [X] Add support for conditional expressions
- [X] Add support for top-level attributes
- [ ] Add support for identifier evaluation
- [ ] Add support for function evaluation
- [ ] Add support for parsing interpolations/templates
- [ ] Add support for evaluating interpolations/templates
- [ ] Add support for heredocs
- [ ] More validations, better parse errors
- [ ] Investigate directives
- [ ] Add support for `for` expressions

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
