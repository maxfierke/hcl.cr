require "../spec_helper"

class TestDocument
  include HCL::Serializable
  include HCL::Serializable::Strict

  @[HCL::Attribute(key: "an_attr")]
  property an_attribute : String

  @[HCL::Attribute]
  property numbered_attr : Int64

  @[HCL::Attribute]
  property hash_map : Hash(String, HCL::Any)

  @[HCL::Attribute(key: "listicle")]
  property list : Array(HCL::Any)

  @[HCL::Block]
  property a_block : TestBlockNoLabels

  @[HCL::Block(key: "b_block")]
  property b_blocks : Array(TestBlockLabels)

  @[HCL::Block]
  property empty_block : TestEmptyBlock
end

class TestBlockNoLabels
  include HCL::Serializable
  include HCL::Serializable::Strict

  @[HCL::Attribute]
  property title : String
end

class TestBlockLabels < TestBlockNoLabels
  @[HCL::Label]
  property which : String

  @[HCL::Label]
  property part : String?
end

class TestEmptyBlock
  include HCL::Serializable
  include HCL::Serializable::Strict
end

describe "Serializable attributes" do
  it "allows parsing an HCL file to according to a schema" do
    src_hcl = <<-HCL
      an_attr = "hello"
      numbered_attr = 123
      hash_map = {
        potato = "yes"
      }
      listicle = ["these", "are", "items", 1, 2, 3]

      a_block {
        title = "The A Block"
      }

      b_block "one" {
        title = "The First B Block"
      }

      b_block "two" "point-one" {
        title = "The Second B Block"
      }

      empty_block {}

    HCL

    parser = HCL::Parser.new(src_hcl)
    doc = parser.parse!

    ctx = HCL::ExpressionContext.default_context
    parsed = TestDocument.new(doc, ctx)

    parsed.an_attribute.should eq("hello")
    parsed.numbered_attr.should eq(123_i64)
    parsed.hash_map["potato"].should eq("yes")
    parsed.list.should eq(["these", "are", "items", 1, 2, 3])
    parsed.a_block.title.should eq("The A Block")
    parsed.b_blocks[0].title.should eq("The First B Block")
    parsed.b_blocks[0].which.should eq("one")
    parsed.b_blocks[0].part.should be_nil
    parsed.b_blocks[1].title.should eq("The Second B Block")
    parsed.b_blocks[1].which.should eq("two")
    parsed.b_blocks[1].part.should eq("point-one")
    parsed.empty_block.should be_a(TestEmptyBlock)
  end
end
