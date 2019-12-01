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
      doc = parser.parse!
      doc.value.should eq({
        "variable" => {
          "ami" => {
            "description" => "the AMI to use"
          }
        }
      })
    end

    it "can parse numbers" do
      hcl_string = <<-HCL
        provider "foo" {
          foo = 0.1
          bar = 1
          baz = "1234"
          biz = "1234.56"
          flim = -6
        }

      HCL

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!
      doc.value.should eq({
        "provider" => {
          "foo" => {
            "foo" => 0.1_f64,
            "bar" => 1_i64,
            "baz" => "1234",
            "biz" => "1234.56",
            "flim" => -6_i64
          }
        }
      })
    end

    it "can parse operators" do
      hcl_string = <<-HCL
        provider "foo" {
          foo = 0.1 * 0.5
          bar = 1 + 8
          baz = 4 % 3
          biz = 9 - 3
          boingo = 6 / 2
          flim = 9 / 4
          flam = !false
          bim = false || true
          bam = null && true
          gt = 2 > 1
          gte = 3 >= 3
          lt = 6 < 7
          lte = 12 <= 6
          eq = 0 == 0
          neq = 12 != 12
          double_not = !(!false)
        }

      HCL

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!
      doc.value.should eq({
        "provider" => {
          "foo" => {
            "foo" => 0.1_f64 * 0.5_f64,
            "bar" => 9_i64,
            "baz" => 1_i64,
            "biz" => 6_i64,
            "boingo" => 3_f64,
            "flim" => 9.0_f64 / 4.0_f64,
            "flam" => true,
            "bim"  => true,
            "bam"  => nil,
            "gt"   => true,
            "gte"  => true,
            "lt"   => true,
            "lte"  => false,
            "eq"   => true,
            "neq"  => false,
            "double_not" => false
          }
        }
      })
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
      doc = parser.parse!
      doc.value.should eq({
        "resource" => {
          "aws_instance" => {
            "web" => {
              "source_dest_check" => false,
              "another_boolean"   => "true",
              "something_i_want_default" => nil
            }
          }
        }
      })
    end

    it "can parse attributes set at the root level" do
      hcl_string = <<-HEREDOC
        hello = "it's me"
        works = true

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!
      doc.value.should eq({
        "hello" => "it's me",
        "works" => true
      })
    end

    it "can parse conditional expressions" do
      hcl_string = <<-HEREDOC
        resource "aws_instance" "web" {
          ami_id = true ? "spatula" : 5
          size = false ? 1 : 9
          region = null ? "hello" : "world"
          something_numeric = 0 ? 2 : 8
          an_op = 3 > 2 ? 5 : 3
          an_array = [1, 2] ? 8 : 1
        }

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!
      doc.value.should eq({
        "resource" => {
          "aws_instance" => {
            "web" => {
              "ami_id" => "spatula",
              "size"   => 9,
              "region" => "world",
              "something_numeric" => 8,
              "an_op" => 5,
              "an_array" => 8
            }
          }
        }
      })
    end

    it "can parse map values" do
      hcl_string = <<-HCL
        config "hello" {
          yoo = "yes"
          development = {
            some_setting = true,
            another_prop = 123,
            maybe_a_list = [123, 231]
          }
        }

      HCL

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!
      doc.value.should eq({
        "config" => {
          "hello" => {
            "yoo" => "yes",
            "development" => {
              "some_setting" => true,
              "another_prop" => 123_i64,
              "maybe_a_list" => [
                123_i64,
                231_i64
              ]
            }
          }
        }
      })
    end

    it "can parse multiple levels of maps and lists" do
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
      doc = parser.parse!
      doc.value.should eq({
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
      })
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
      doc = parser.parse!
      doc.value.should eq({
        "variable" => {
          "ami" => {"description" => "the AMI to use"}
        },
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
      })
    end

    it "can parse property & index access" do
      hcl_string = <<-HEREDOC
        resource "aws_instance" "web" {
          ami = { something = "evil this way comes" }.something
          security_group_id = [1, 2, 3][0]
        }

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!
      doc.value.should eq({
        "resource" => {
          "aws_instance" => {
            "web" => {
              "ami" => "evil this way comes",
              "security_group_id" => 1_i64
            }
          }
        }
      })
    end

    pending "can parse nested identifiers" do
      hcl_string = <<-HEREDOC
        resource "aws_instance" "web" {
          ami = var.something.ami_id
        }

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!
      doc.value.should eq({
        "resource" => {
          "aws_instance" => {
            "web" => {
              # TODO: This is a bit wrong
              "ami" => "var.something.ami_id"
            }
          }
        }
      })
    end

    it "can parse function calls" do
      hcl_string = <<-HCL
        config "hello" {
          yoo = some_function(item1, [1, 2, 3], "hello")
        }

      HCL

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!
      doc.value.should eq({
        "config" => {
          "hello" => {
            # TODO: This is wrong.
            "yoo" => nil
          }
        }
      })
    end
  end
end
