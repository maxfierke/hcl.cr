require "../spec_helper"

class SomeFunction < HCL::Function
  def initialize
    super("some_function", arity: 3)
  end

  def call(args) : HCL::ValueType
    arg1 = args[0].unwrap
    arg2 = args[1].unwrap
    arg3 = args[2].unwrap

    HCL::ValueType.new("#{arg3} #{arg1} #{arg2}")
  end
end

describe HCL::Parser do
  describe "#parse" do
    it "can parse simple strings" do
      hcl_string = <<-HEREDOC
        variable "ami" {
          description = "the AMI to use"
        }

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!
      doc.unwrap.should eq({
        "variable" => {
          "ami" => {
            "description" => "the AMI to use"
          }
        }
      })
    end

    it "can parse strings w/ escapes" do
      hcl_string = <<-'HEREDOC'
        variable "ami" {
          description = "the \"AMI to use"
        }

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!
      doc.unwrap.should eq({
        "variable" => {
          "ami" => {
            "description" => "the \\\"AMI to use"
          }
        }
      })
    end

    it "can parse heredocs" do
      hcl_string = <<-HEREDOC
        description = <<-DOC
          once upon a time
          there was a complicated
          parsing rule
        DOC
        another_prop = "hello"

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!
      doc.unwrap.should eq({
        "description" => "once upon a time\nthere was a complicated\nparsing rule\n",
        "another_prop" => "hello"
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
      doc.unwrap.should eq({
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
      doc.unwrap.should eq({
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
      doc.unwrap.should eq({
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
      doc.unwrap.should eq({
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
      doc.unwrap.should eq({
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
      doc.unwrap.should eq({
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
      doc.unwrap.should eq({
        "test" => {
          "hello" => {
            "resource" => [
              {
                "foo" => [
                  {
                    "bar" => {} of String => HCL::ValueType
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
      doc.unwrap.should eq({
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
      doc.unwrap.should eq({
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

    it "can parse nested identifiers" do
      hcl_string = <<-HEREDOC
        resource "aws_instance" "web" {
          ami = var.something.ami_id
        }

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!

      ctx = HCL::ExpressionContext.new
      ctx.variables["var"] = HCL::ValueType.new(
        Hash(String, HCL::ValueType).new.tap { |hsh|
          hsh["something"] = HCL::ValueType.new(
            Hash(String, HCL::ValueType).new.tap { |nested|
              nested["ami_id"] = HCL::ValueType.new("ami-1234")
            }
          )
        }
      )

      doc.unwrap(ctx).should eq({
        "resource" => {
          "aws_instance" => {
            "web" => {
              "ami" => "ami-1234"
            }
          }
        }
      })
    end

    it "can parse complex nested structure traversals" do
      hcl_string = <<-HEREDOC
        resource "aws_instance" "web" {
          ami = var.something[0].other_thing.some_list[0].ami_id
        }

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!

      ctx = HCL::ExpressionContext.new
      ctx.variables["var"] = HCL::ValueType.new(
        Hash(String, HCL::ValueType).new.tap { |var|
          something = [] of HCL::ValueType
          something << HCL::ValueType.new(
            Hash(String, HCL::ValueType).new.tap { |something_0|
              other_thing = Hash(String, HCL::ValueType).new.tap do |other_thing|
                some_list = [] of HCL::ValueType
                some_list << HCL::ValueType.new(
                  Hash(String, HCL::ValueType).new.tap { |nested|
                    nested["ami_id"] = HCL::ValueType.new("ami-1234")
                  }
                )
                other_thing["some_list"] = HCL::ValueType.new(some_list)
              end

              something_0["other_thing"] = HCL::ValueType.new(other_thing)
            }
          )
          var["something"] = HCL::ValueType.new(something)
        }
      )

      doc.unwrap(ctx).should eq({
        "resource" => {
          "aws_instance" => {
            "web" => {
              "ami" => "ami-1234"
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

      ctx = HCL::ExpressionContext.new
      ctx.functions["some_function"] = SomeFunction.new
      ctx.variables["item1"] = HCL::ValueType.new("world")

      doc.unwrap(ctx).should eq({
        "config" => {
          "hello" => {
            "yoo" => "hello world [1, 2, 3]"
          }
        }
      })
    end

    it "can parse varadic function calls" do
      hcl_string = <<-HCL
        config "hello" {
          yoo = format("hello %d %d %d", numbers...)
        }

      HCL

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!

      ctx = HCL::ExpressionContext.default_context
      ctx.variables["numbers"] = HCL::ValueType.new([
        HCL::ValueType.new(1_i64),
        HCL::ValueType.new(2_i64),
        HCL::ValueType.new(3_i64)
      ])

      doc.unwrap(ctx).should eq({
        "config" => {
          "hello" => {
            "yoo" => "hello 1 2 3"
          }
        }
      })
    end
  end
end
