require "./hcl"

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
  test = var.thing.list[2].other_thing["hello"]

  connection {
    user = "root"
  }
}
HEREDOC

parser = HCL::Parser.new(SRC_TEXT)
tokens = parser.parse
pp! tokens

values = tokens.map { |token| token.value }
pp! values

string = tokens.map { |token| token.string }.join('\n')
puts string
