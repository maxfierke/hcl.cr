require "../spec_helper"

class TestBlock
  include HCL::Serializable

  @[HCL::Attribute]
  property title : String
end

class UnmappedTestBlock < TestBlock
  include HCL::Serializable::Unmapped
end

class StrictTestBlock < TestBlock
  include HCL::Serializable::Unmapped
end

class TestEmptyBlock
  include HCL::Serializable
end

class TestBlockLabels < TestBlock
  @[HCL::Label]
  property which : String

  @[HCL::Label]
  property part : String?
end

class StrictTestBlockLabels < TestBlockLabels
  include HCL::Serializable::Strict
end

class UnmappedTestBlockLabels < TestBlockLabels
  include HCL::Serializable::Unmapped
end

class TestDocument(TB, TBL)
  include HCL::Serializable

  @[HCL::Attribute(key: "an_attr")]
  property an_attribute : String

  @[HCL::Attribute]
  property numbered_attr : Int64

  @[HCL::Attribute]
  property hash_map : Hash(String, HCL::Any)

  @[HCL::Attribute(key: "listicle")]
  property list : Array(HCL::Any)

  @[HCL::Block]
  property a_block : TB

  @[HCL::Block(key: "b_block")]
  property b_blocks : Array(TBL)

  @[HCL::Block]
  property empty_block : TestEmptyBlock
end

class LaxTestDocument < TestDocument(TestBlock, TestBlockLabels)
end

class StrictTestDocument < TestDocument(StrictTestBlock, StrictTestBlockLabels)
  include HCL::Serializable::Strict
end

class UnmappedTestDocument < TestDocument(UnmappedTestBlock, UnmappedTestBlockLabels)
  include HCL::Serializable::Unmapped
end

describe "HCL::Serializable" do
  valid_src_hcl = <<-HCL
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

  it "allows parsing an HCL file to according to a schema" do
    parser = HCL::Parser.new(valid_src_hcl)
    doc = parser.parse!

    ctx = HCL::ExpressionContext.default_context
    parsed = LaxTestDocument.new(doc, ctx)

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

  it "raises an error on missing attributes" do
    src_hcl = <<-HCL
    an_attr = "hello"

    HCL

    parser = HCL::Parser.new(src_hcl)
    doc = parser.parse!
    ctx = HCL::ExpressionContext.default_context

    expect_raises(
      HCL::ParseException,
      "Missing HCL attribute 'numbered_attr' for document"
    ) do
      LaxTestDocument.new(doc, ctx)
    end
  end

  it "raises an error on missing blocks" do
    src_hcl = <<-HCL
    an_attr = ""
    numbered_attr = 0
    hash_map = {}
    listicle = []

    HCL

    parser = HCL::Parser.new(src_hcl)
    doc = parser.parse!
    ctx = HCL::ExpressionContext.default_context

    expect_raises(
      HCL::ParseException,
      "Missing HCL block 'a_block' for document"
    ) do
      LaxTestDocument.new(doc, ctx)
    end
  end

  it "raises an error on missing labels" do
    src_hcl = <<-HCL
    some_block {
      title = "I am a Block"
    }

    HCL

    parser = HCL::Parser.new(src_hcl)
    doc = parser.parse!
    ctx = HCL::ExpressionContext.default_context

    block_node = doc.blocks.find { |b| b.id == "some_block" }.not_nil!

    expect_raises(
      HCL::ParseException,
      "Missing HCL label at index 0 for block 'some_block'"
    ) do
      TestBlockLabels.new(block_node, ctx)
    end
  end

  it "ignores unmapped attributes" do
    src_hcl = <<-HCL
    #{valid_src_hcl}

    some_attribute_not_mapped = true

    HCL

    parser = HCL::Parser.new(src_hcl)
    doc = parser.parse!
    ctx = HCL::ExpressionContext.default_context

    parsed = LaxTestDocument.new(doc, ctx)
    parsed.an_attribute.should eq("hello")
    parsed.responds_to?(:some_attribute_not_mapped).should eq(false)
  end

  it "ignores unmapped blocks" do
    src_hcl = <<-HCL
    #{valid_src_hcl}

    novel_block {
      an_attr = "yo"
    }

    HCL

    parser = HCL::Parser.new(src_hcl)
    doc = parser.parse!
    ctx = HCL::ExpressionContext.default_context

    parsed = LaxTestDocument.new(doc, ctx)
    parsed.empty_block.should be_a(TestEmptyBlock)
    parsed.responds_to?(:novel_block).should eq(false)
  end

  it "ignores unmapped labels" do
    src_hcl = <<-HCL
    some_block "one" "point-one" "undefined" {
      title = "I am a Block"
    }

    HCL

    parser = HCL::Parser.new(src_hcl)
    doc = parser.parse!
    ctx = HCL::ExpressionContext.default_context

    block_node = doc.blocks.find { |b| b.id == "some_block" }.not_nil!

    parsed = TestBlockLabels.new(block_node, ctx)
    parsed.which.should eq("one")
    parsed.part.should eq("point-one")
  end

  describe "HCL::Serializable::Strict" do
    it "raises on unmapped attributes" do
      src_hcl = <<-HCL
      #{valid_src_hcl}

      some_attribute_not_mapped = true

      HCL

      parser = HCL::Parser.new(src_hcl)
      doc = parser.parse!
      ctx = HCL::ExpressionContext.default_context

      expect_raises(
        HCL::ParseException,
        "Unknown HCL attribute 'some_attribute_not_mapped' for document"
      ) do
        StrictTestDocument.new(doc, ctx)
      end
    end

    it "raises on unmapped blocks" do
      src_hcl = <<-HCL
      #{valid_src_hcl}

      novel_block {}

      HCL

      parser = HCL::Parser.new(src_hcl)
      doc = parser.parse!
      ctx = HCL::ExpressionContext.default_context

      expect_raises(
        HCL::ParseException,
        "Unknown HCL block 'novel_block' for document"
      ) do
        StrictTestDocument.new(doc, ctx)
      end
    end

    it "raises on unmapped labels" do
      src_hcl = <<-HCL
      some_block "one" "point-one" "undefined" {
        title = "I am a Block"
      }

      HCL

      parser = HCL::Parser.new(src_hcl)
      doc = parser.parse!
      ctx = HCL::ExpressionContext.default_context

      block_node = doc.blocks.find { |b| b.id == "some_block" }.not_nil!

      expect_raises(
        HCL::ParseException,
        "Unknown HCL label at index 2 for block 'some_block': \"undefined\""
      ) do
        StrictTestBlockLabels.new(block_node, ctx)
      end
    end
  end

  describe "HCL::Serializable::Unmapped" do
    it "saves unmapped attributes" do
      src_hcl = <<-HCL
      #{valid_src_hcl}

      some_attribute_not_mapped = true

      HCL

      parser = HCL::Parser.new(src_hcl)
      doc = parser.parse!
      ctx = HCL::ExpressionContext.default_context

      parsed = UnmappedTestDocument.new(doc, ctx)
      parsed.hcl_unmapped_attributes["some_attribute_not_mapped"].should eq(true)
    end

    it "saves unmapped blocks" do
      src_hcl = <<-HCL
      #{valid_src_hcl}

      novel_block {
        an_attr = "yo"
      }

      array_block "one" {
        index = 0
      }

      array_block "two" {
        index = 1
      }

      HCL

      parser = HCL::Parser.new(src_hcl)
      doc = parser.parse!
      ctx = HCL::ExpressionContext.default_context

      parsed = UnmappedTestDocument.new(doc, ctx)
      parsed.hcl_unmapped_blocks["novel_block"].should eq({ "an_attr" => "yo" })
      parsed.hcl_unmapped_blocks["array_block"].should eq([
        { "one" => { "index" => 0 } },
        { "two" => { "index" => 1 } }
      ])
    end

    it "saves unmapped labels" do
      src_hcl = <<-HCL
      some_block "one" "point-one" "undefined" {
        title = "I am a Block"
      }

      HCL

      parser = HCL::Parser.new(src_hcl)
      doc = parser.parse!
      ctx = HCL::ExpressionContext.default_context

      block_node = doc.blocks.find { |b| b.id == "some_block" }.not_nil!

      parsed = UnmappedTestBlockLabels.new(block_node, ctx)
      parsed.which.should eq("one")
      parsed.part.should eq("point-one")
      parsed.hcl_unmapped_labels[2].should eq("undefined")
    end
  end
end
