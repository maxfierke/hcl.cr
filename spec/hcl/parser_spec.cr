require "../spec_helper"

describe HCL::Parser do
  describe "#parse" do
    it "can parse strings" do
      hcl_string = <<-HEREDOC
        variable "ami" {
          description = "the AMI to use"
        }

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      parser.values.should eq([
        {
          "variable" => {
            "ami" => {
              "description" => "the AMI to use"
            }
          }
        }
      ])
    end

    it "can parse numbers" do
      hcl_string = <<-HCL
        provider "foo" {
          foo = 0.1
          bar = 1
          baz = "1234"
          biz = "1234.56"
        }

      HCL
      parser = HCL::Parser.new(hcl_string)

      parser.values.should eq([
        {
          "provider" => {
            "foo" => {
              "foo" => 0.1_f64,
              "bar" => 1_i64,
              "baz" => "1234",
              "biz" => "1234.56"
            }
          }
        }
      ])
    end

    it "can parse booleans & nulls" do
      hcl_string = <<-HEREDOC
        resource "aws_instance" "web" {
          source_dest_check = false
          another_boolean = "true"
          something_i_want_default = null
        }

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      parser.values.should eq([
        {
          "resource" => {
            "aws_instance" => {
              "web" => {
                "source_dest_check" => false,
                "another_boolean"   => "true",
                "something_i_want_default" => nil
              }
            }
          }
        }
      ])
    end

    it "can parse map values" do
      hcl_string = <<-HCL
        config "hello" {
          yoo = "yes"
          development = {
            some_setting = true
          }
        }

      HCL
      parser = HCL::Parser.new(hcl_string)

      parser.values.should eq([
        {
          "config" => {
            "hello" => {
              "yoo" => "yes",
              "development" => {
                "some_setting" => true
              }
            }
          }
        }
      ])
    end

    pending "can parse multiple levels of maps and lists" do
      hcl_string = <<-HCL
        test "hello" {
          resource = [{
            foo = [{
              bar = {}
            }]
          }]
        }
      HCL

      parser = HCL::Parser.new(hcl_string)

      parser.values.should eq([
        {
          "test" => {
            "hello" => {
              "resource" => [
                {
                  "foo" => [
                    {
                      "bar" => {} of String => HCL::AST::ValueType
                    }
                  ]
                }
              ]
            }
          }
        }
      ])
    end

    it "can parse multiple blocks with nesting" do
      hcl_string = <<-HEREDOC
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

            something "else" {
              foo = "bar"
            }
          }
        }

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      parser.values.should eq([
        {
          "variable" => {
            "ami" => {"description" => "the AMI to use"}
          }
        },
        {
          "resource" => {
            "aws_instance" => {
              "web" => {
                "ami" => "${var.ami}",
                "count" => 2,
                "source_dest_check" => false,
                "another_boolean" => "true",
                "something_i_want_default" => nil,
                "connection" => {
                  "user" => "root",
                  "something" => {
                    "else" => {
                      "foo" => "bar"
                    }
                  }
                }
              }
            }
          }
        }
      ])
    end

    pending "can parse nested identifiers" do
      hcl_string = <<-HEREDOC
        resource "aws_instance" "web" {
          ami = var.something.ami_id
        }
      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      parser.values.should eq([
        {
          "resource" => {
            "aws_instance" => {
              "web" => {
                # TODO: This is a bit wrong
                "ami" => "var.something.ami_id"
              }
            }
          }
        }
      ])
    end

    it "can parse function calls" do
      hcl_string = <<-HCL
        config "hello" {
          yoo = some_function(item1, [1, 2, 3], "hello")
        }

      HCL
      parser = HCL::Parser.new(hcl_string)

      parser.values.should eq([
        {
          "config" => {
            "hello" => {
              # TODO: This is wrong.
              "yoo" => nil
            }
          }
        }
      ])
    end
  end
end
