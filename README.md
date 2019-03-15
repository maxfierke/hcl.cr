# hcl.cr

A general-purpose HCL parser written in Crystal. Does not make any domain assumptions.
Supports the standard HCL types, including blocks and lists. Does not support functions.

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

tokens = parser.parse # Returns an Array(HCL::Token)
values = parser.value # Returns the HCL structure as Crystal data types
string = parser.string # Returns string reconstruction of HCL configuration
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## TODO

- [X] Add support for maps
- [X] Add support for functions
- [ ] Add support for heredocs
- [ ] More validations
- [ ] Automatically resolve interpolations

## Contributing

1. Fork it (<https://github.com/maxfierke/hcl.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Max Fierke](https://github.com/maxfierke) - creator and maintainer
