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

  connection {
    user = "root"
    port = 100 + 2
  }
}

# One-line block
data "a_single_datum" { foo = "bar" }

HEREDOC

puts "#" * 80
puts "START PEGMATITE"
puts "#" * 80
Pegmatite.tokenize(HCL::Grammar, SRC_TEXT, io: STDOUT)
puts "#" * 80
puts "END PEGMATITE"
puts "#" * 80

parser = HCL::Parser.new(SRC_TEXT)
tokens = parser.parse
puts "#" * 80
puts "START TOKEN DUMP"
puts "#" * 80
pp! tokens
puts "#" * 80
puts "END TOKEN DUMP"
puts "#" * 80

values = tokens.map { |token| token.value }
puts "#" * 80
puts "START TOKEN VALUE DUMP"
puts "#" * 80
pp! values
puts "#" * 80
puts "END TOKEN VALUE DUMP"
puts "#" * 80

string = tokens.map { |token| token.string }.join('\n')
puts "#" * 80
puts "START TOKEN STRING DUMP"
puts "#" * 80
puts string
puts "#" * 80
puts "END TOKEN STRING DUMP"
puts "#" * 80
