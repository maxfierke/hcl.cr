require "./hcl"

SRC_TEXT = <<-'HEREDOC'
document_attr = "i am here at the top"

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

# escaping strings
variable "token" {
  my_secure_password = "something \"with a quote"
}


# heredocs
variable "prose" {
  value = <<-PROSE
    there once
    was a story
  PROSE
}

HEREDOC

puts "#" * 80
puts "START PEGMATITE"
puts "#" * 80
Pegmatite.tokenize(HCL::Grammar, SRC_TEXT, io: STDOUT)
puts "#" * 80
puts "END PEGMATITE"
puts "#" * 80

parser = HCL::Parser.new(SRC_TEXT)
doc = parser.parse!
puts "#" * 80
puts "START DOCUMENT DUMP"
puts "#" * 80
pp! doc
puts "#" * 80
puts "END DOCUMENT DUMP"
puts "#" * 80

doc_value = doc.value
puts "#" * 80
puts "START DOC VALUE DUMP"
puts "#" * 80
pp! doc_value
puts "#" * 80
puts "END DOC VALUE DUMP"
puts "#" * 80

doc_unwrap = doc.unwrap
puts "#" * 80
puts "START DOC UNWRAP DUMP"
puts "#" * 80
pp! doc_unwrap
puts "#" * 80
puts "END DOC UNWRAP DUMP"
puts "#" * 80

string = doc.to_s
puts "#" * 80
puts "START DOC STRING DUMP"
puts "#" * 80
puts string
puts "#" * 80
puts "END DOC STRING DUMP"
puts "#" * 80
