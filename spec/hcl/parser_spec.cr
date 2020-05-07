require "../spec_helper"

class SomeFunction < HCL::Function
  def initialize
    super("some_function", arity: 3)
  end

  def call(args) : HCL::Any
    HCL::Any.new("#{args[2]} #{args[0]} #{args[1]}")
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
      doc.evaluate.should eq({
        "variable" => {
          "ami" => {
            "description" => "the AMI to use",
          },
        },
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
      doc.evaluate.should eq({
        "variable" => {
          "ami" => {
            "description" => "the \\\"AMI to use",
          },
        },
      })
    end

    it "can parse heredocs" do
      hcl_string = <<-HEREDOC
        description = <<-DOC
          once upon a time
          there was a complicated
          parsing rule
        DOC
        interpolated = <<-DOC
          one bottle of ${var.beverage} on the wall
          one bottle of ${var.beverage}
          take it down
        DOC
        another_prop = "hello"

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!

      ctx = HCL::ExpressionContext.new
      ctx.variables["var"] = HCL::Any.new({
        "beverage" => "beer",
      })

      doc.evaluate(ctx).should eq({
        "description"  => "once upon a time\nthere was a complicated\nparsing rule\n",
        "interpolated" => "one bottle of beer on the wall\none bottle of beer\ntake it down\n",
        "another_prop" => "hello",
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
      doc.evaluate.should eq({
        "provider" => {
          "foo" => {
            "foo"  => 0.1_f64,
            "bar"  => 1_i64,
            "baz"  => "1234",
            "biz"  => "1234.56",
            "flim" => -6_i64,
          },
        },
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
      doc.evaluate.should eq({
        "provider" => {
          "foo" => {
            "foo"        => 0.1_f64 * 0.5_f64,
            "bar"        => 9_i64,
            "baz"        => 1_i64,
            "biz"        => 6_i64,
            "boingo"     => 3_f64,
            "flim"       => 9.0_f64 / 4.0_f64,
            "flam"       => true,
            "bim"        => true,
            "bam"        => nil,
            "gt"         => true,
            "gte"        => true,
            "lt"         => true,
            "lte"        => false,
            "eq"         => true,
            "neq"        => false,
            "double_not" => false,
          },
        },
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
      doc.evaluate.should eq({
        "resource" => {
          "aws_instance" => {
            "web" => {
              "source_dest_check"        => false,
              "another_boolean"          => true,
              "something_i_want_default" => nil,
            },
          },
        },
      })
    end

    it "can parse attributes set at the root level" do
      hcl_string = <<-HEREDOC
        hello = "it's me"
        works = true

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!
      doc.evaluate.should eq({
        "hello" => "it's me",
        "works" => true,
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
      doc.evaluate.should eq({
        "resource" => {
          "aws_instance" => {
            "web" => {
              "ami_id"            => "spatula",
              "size"              => 9,
              "region"            => "world",
              "something_numeric" => 8,
              "an_op"             => 5,
              "an_array"          => 8,
            },
          },
        },
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
          json = {
            key: "value",
            other_key: "other_value"
          }
        }

      HCL

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!
      doc.evaluate.should eq({
        "config" => {
          "hello" => {
            "yoo"         => "yes",
            "development" => {
              "some_setting" => true,
              "another_prop" => 123_i64,
              "maybe_a_list" => [
                123_i64,
                231_i64,
              ],
            },
            "json" => {
              "key"       => "value",
              "other_key" => "other_value",
            },
          },
        },
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
      doc.evaluate.should eq({
        "test" => {
          "hello" => {
            "resource" => [
              {
                "foo" => [
                  {
                    "bar" => {} of String => HCL::Any,
                  },
                ],
              },
            ],
          },
        },
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
          ami               = "ami-12345"
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
      doc.evaluate.should eq({
        "variable" => {
          "ami" => {"description" => "the AMI to use"},
        },
        "resource" => {
          "aws_instance" => {
            "web" => {
              "ami"                      => "ami-12345",
              "count"                    => 2,
              "source_dest_check"        => false,
              "another_boolean"          => true,
              "something_i_want_default" => nil,
              "connection"               => {
                "user"      => "root",
                "something" => {
                  "else" => {
                    "foo" => "bar",
                  },
                },
              },
            },
          },
        },
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
      doc.evaluate.should eq({
        "resource" => {
          "aws_instance" => {
            "web" => {
              "ami"               => "evil this way comes",
              "security_group_id" => 1_i64,
            },
          },
        },
      })
    end

    it "can parse splats" do
      hcl_string = <<-HEREDOC
        resource "aws_instance" "web" {
          security_group_ids = security_groups[*].id
        }

      HEREDOC

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!

      ctx = HCL::ExpressionContext.new
      ctx.variables["security_groups"] = HCL::Any.new(
        [
          {"id" => "sg-1234"},
          {"id" => "sg-4567"},
          {"id" => "sg-7890"},
        ]
      )

      doc.evaluate(ctx).should eq({
        "resource" => {
          "aws_instance" => {
            "web" => {
              "security_group_ids" => [
                "sg-1234",
                "sg-4567",
                "sg-7890",
              ],
            },
          },
        },
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
      ctx.variables["var"] = HCL::Any.new(
        {
          "something" => {
            "ami_id" => "ami-1234",
          },
        }
      )

      doc.evaluate(ctx).should eq({
        "resource" => {
          "aws_instance" => {
            "web" => {
              "ami" => "ami-1234",
            },
          },
        },
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
      ctx.variables["var"] = HCL::Any.new(
        {
          "something" => [
            {
              "other_thing" => {
                "some_list" => [
                  {
                    "ami_id" => "ami-1234",
                  },
                ],
              },
            },
          ],
        }
      )

      doc.evaluate(ctx).should eq({
        "resource" => {
          "aws_instance" => {
            "web" => {
              "ami" => "ami-1234",
            },
          },
        },
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
      ctx.variables["item1"] = HCL::Any.new("world")

      doc.evaluate(ctx).should eq({
        "config" => {
          "hello" => {
            "yoo" => "hello world [1, 2, 3]",
          },
        },
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
      ctx.variables["numbers"] = HCL::Any.new([1_i64, 2_i64, 3_i64])

      doc.evaluate(ctx).should eq({
        "config" => {
          "hello" => {
            "yoo" => "hello 1 2 3",
          },
        },
      })
    end

    it "can parse interpolations" do
      hcl_string = <<-HCL
        ec2_instance {
          ami               = "${var.ami}"
          name              = "prd-inst-${var.instance_id}"
          description       = "${"production" ~}${" instance"} in AZ 1"
          region            = "us- ${~ "east-1" }"
          az                = "az$${1}"
        }

      HCL

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!

      ctx = HCL::ExpressionContext.default_context
      ctx.variables["var"] = HCL::Any.new({
        "ami"         => "ami-abcd1234",
        "instance_id" => "01",
      })

      doc.evaluate(ctx).should eq({
        "ec2_instance" => {
          "ami"         => "ami-abcd1234",
          "name"        => "prd-inst-01",
          "description" => "production instance in AZ 1",
          "region"      => "us-east-1",
          "az"          => "az$${1}",
        },
      })
    end

    it "can perform interpolation unwrapping" do
      hcl_string = <<-HCL
        block {
          boolean = "${true}"
          wrapped_boolean = "${"${true}"}"
          mixed_types = "hello ${true}"
          empties = "${""}${true}"
          cond = "%{ if true ~} false %{~ endif }"
        }

      HCL

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!

      doc.evaluate.should eq({
        "block" => {
          "boolean"         => true,
          "wrapped_boolean" => true,
          "mixed_types"     => "hello true",
          "empties"         => "true",
          "cond"            => false,
        },
      })
    end

    it "can parse for expressions" do
      hcl_string = <<-HCL
          block {
            each = [for v in ["a", "b"]: v]
            each_with_index = [for i, v in ["a", "b"]: i]
            hash_each = {for i, v in ["a", "b"]: v => i}
            cond_each = [for i, v in ["a", "b", "c"]: v if i < 2]
          }

        HCL

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!

      doc.evaluate.should eq({
        "block" => {
          "each"            => ["a", "b"],
          "each_with_index" => [0, 1],
          "hash_each"       => {"a" => 0, "b" => 1},
          "cond_each"       => ["a", "b"],
        },
      })
    end

    it "can parse template directives" do
      hcl_string = <<-HCL
        block {
          cond = "%{ if true ~} hello %{~ endif }"
          for_expr = "%{ for v in [true, 1, "hello"] }${v}%{ endfor }"
        }

      HCL

      parser = HCL::Parser.new(hcl_string)
      doc = parser.parse!

      doc.evaluate.should eq({
        "block" => {
          "cond"     => "hello",
          "for_expr" => "true1hello",
        },
      })
    end
  end
end
