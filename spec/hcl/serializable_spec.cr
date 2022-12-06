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

class Location
  include HCL::Serializable

  @[HCL::Attribute(key: "lat")]
  property latitude : Float64

  @[HCL::Attribute(key: "lng")]
  property longitude : Float64
end

class House
  include HCL::Serializable

  @[HCL::Attribute]
  property address : String

  @[HCL::Block(presence: true)]
  property location : Location?

  getter? location_present : Bool
end

class NativeTypesDocument
  include HCL::Serializable

  @[HCL::Attribute]
  property dictionary : Hash(String, String)

  @[HCL::Attribute]
  property strings : Array(String)

  @[HCL::Attribute]
  property union_list : Array(String | Int64)
end

class DynamicTypesDocument
  include HCL::Serializable

  @[HCL::Attribute]
  property what_could_it_be : HCL::Any

  @[HCL::Attribute]
  property dictionary : Hash(String, HCL::Any)

  @[HCL::Attribute]
  property grab_bag : Array(HCL::Any)
end

hcl_house = <<-HCL
  address = "Crystal Road 1234"
  location {
    lat = 12.3
    lng = 34.5
  }

HCL

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
    parsed = LaxTestDocument.from_hcl(valid_src_hcl)

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

  it "allows parsing an HCL file mapped to complex native types" do
    parsed = NativeTypesDocument.from_hcl(<<-HCL)
    dictionary = {
      hello = "world",
      goodbye = "moon"
    }

    strings = ["yarn", "twine", "nylon"]
    union_list = ["the answer is", 42]

    HCL

    parsed.dictionary.should eq({
      "hello"   => "world",
      "goodbye" => "moon",
    })
    parsed.strings.should eq(["yarn", "twine", "nylon"])
    parsed.union_list.should eq(["the answer is", 42])
  end

  it "allows parsing an HCL file mapped to a dynamic HCL type" do
    parsed = DynamicTypesDocument.from_hcl(<<-HCL)
    what_could_it_be = "anything!!"
    dictionary = {
      hello = "world",
      goodbye = "moon"
    }

    grab_bag = [123, "blue", true]
    union_list = ["the answer is", 42, true]

    HCL

    parsed.what_could_it_be.should eq(HCL::Any.new("anything!!"))
    parsed.dictionary.should eq({
      "hello"   => HCL::Any.new("world"),
      "goodbye" => HCL::Any.new("moon"),
    })
    parsed.grab_bag.should eq([HCL::Any.new(123_i64), HCL::Any.new("blue"), HCL::Any.new(true)])
  end

  it "allows rendering an HCL file from a schema" do
    parsed = LaxTestDocument.from_hcl(valid_src_hcl)
    rendered = parsed.to_hcl

    rendered.should eq(valid_src_hcl)
  end

  it "allows parsing an HCL file according to a schema with nilable blocks" do
    house = House.from_hcl(hcl_house)
    house.address.should eq("Crystal Road 1234")
    house.location.should_not be_nil
    house.location_present?.should eq(true)
    loc = house.location.not_nil!
    loc.latitude.should eq(12.3)
    loc.longitude.should eq(34.5)

    house = House.from_hcl("address = \"Crystal Road 1234\"\n")
    house.address.should eq("Crystal Road 1234")
    house.location.should be_nil
    house.location_present?.should eq(false)
  end

  it "allows rendering an HCL file from a schema with nilable blocks" do
    house = House.from_hcl(hcl_house)

    house.to_hcl.should eq(<<-HCL)
    address = "Crystal Road 1234"

    location {
      lat = 12.3
      lng = 34.5
    }

    HCL
  end

  it "raises an error on missing attributes" do
    src_hcl = <<-HCL
    an_attr = "hello"

    HCL

    expect_raises(
      HCL::ParseException,
      "Missing HCL attribute 'numbered_attr' for document"
    ) do
      LaxTestDocument.from_hcl(src_hcl)
    end
  end

  it "raises an error on missing blocks" do
    src_hcl = <<-HCL
    an_attr = ""
    numbered_attr = 0
    hash_map = {}
    listicle = []

    HCL

    expect_raises(
      HCL::ParseException,
      "Missing HCL block 'a_block' for document"
    ) do
      LaxTestDocument.from_hcl(src_hcl)
    end
  end

  it "raises an error on missing labels" do
    src_hcl = <<-HCL
    some_block {
      title = "I am a Block"
    }

    HCL

    doc = HCL::Parser.parse!(src_hcl)
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

    parsed = LaxTestDocument.from_hcl(src_hcl)
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

    parsed = LaxTestDocument.from_hcl(src_hcl)
    parsed.empty_block.should be_a(TestEmptyBlock)
    parsed.responds_to?(:novel_block).should eq(false)
  end

  it "ignores unmapped labels" do
    src_hcl = <<-HCL
    some_block "one" "point-one" "undefined" {
      title = "I am a Block"
    }

    HCL

    doc = HCL::Parser.parse!(src_hcl)
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

      expect_raises(
        HCL::ParseException,
        "Unknown HCL attribute 'some_attribute_not_mapped' for document"
      ) do
        StrictTestDocument.from_hcl(src_hcl)
      end
    end

    it "raises on unmapped blocks" do
      src_hcl = <<-HCL
      #{valid_src_hcl}

      novel_block {}

      HCL

      expect_raises(
        HCL::ParseException,
        "Unknown HCL block 'novel_block' for document"
      ) do
        StrictTestDocument.from_hcl(src_hcl)
      end
    end

    it "raises on unmapped labels" do
      src_hcl = <<-HCL
      some_block "one" "point-one" "undefined" {
        title = "I am a Block"
      }

      HCL

      doc = HCL::Parser.parse!(src_hcl)
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

      doc = HCL::Parser.parse!(src_hcl)
      ctx = HCL::ExpressionContext.default_context

      parsed = UnmappedTestDocument.new(doc, ctx)
      parsed.hcl_unmapped_attributes["some_attribute_not_mapped"].should eq(
        doc.attributes["some_attribute_not_mapped"]
      )

      parsed.to_hcl.should eq(<<-HCL)
      an_attr = "hello"
      numbered_attr = 123
      hash_map = {
        potato = "yes"
      }
      listicle = ["these", "are", "items", 1, 2, 3]
      some_attribute_not_mapped = true

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

      doc = HCL::Parser.parse!(src_hcl)
      ctx = HCL::ExpressionContext.default_context

      parsed = UnmappedTestDocument.new(doc, ctx)
      parsed.hcl_unmapped_blocks["novel_block"].should eq(
        doc.blocks.select { |block| block.id == "novel_block" }
      )
      parsed.hcl_unmapped_blocks["array_block"].should eq(
        doc.blocks.select { |block| block.id == "array_block" }
      )

      parsed.to_hcl.should eq(src_hcl)
    end

    it "saves unmapped labels" do
      src_hcl = <<-HCL
      #{valid_src_hcl}
      b_block "one" "point-one" "undefined" {
        title = "I am a Block"
      }

      HCL

      doc = HCL::Parser.parse!(src_hcl)
      ctx = HCL::ExpressionContext.default_context

      block_node = doc.blocks.select { |b| b.id == "b_block" }.last

      parsed = UnmappedTestDocument.new(doc, ctx)
      parsed.b_blocks.last.which.should eq("one")
      parsed.b_blocks.last.part.should eq("point-one")
      parsed.b_blocks.last.hcl_unmapped_labels[2].should eq(block_node.labels[2])

      parsed.to_hcl.should eq(<<-HCL)
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

      b_block "one" "point-one" "undefined" {
        title = "I am a Block"
      }

      empty_block {}

      HCL
    end
  end
end
