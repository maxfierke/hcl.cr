require "../../spec_helper"

describe HCL::Functions::HasIndex do
  describe "#matches_arity" do
    it "accepts one argument" do
      fn = HCL::Functions::HasIndex.new

      fn.matches_arity?(0_u32..1_u32).should eq(false)
      fn.matches_arity?(2_u32).should eq(true)
      fn.matches_arity?(3_u32..20_u32).should eq(false)
    end
  end

  describe "#call" do
    it "returns the whether the index exists for the collection" do
      fn = HCL::Functions::HasIndex.new

      fn.call([
        HCL::Any.new(Hash(String, HCL::Any).new),
        HCL::Any.new("hello"),
      ]).should eq(false)
      fn.call([
        HCL::Any.new(Array(HCL::Any).new),
        HCL::Any.new(99_i64),
      ]).should eq(false)
      fn.call([
        HCL::Any.new([
          HCL::Any.new("🧄"),
          HCL::Any.new("🧇"),
        ]),
        HCL::Any.new(0_i64),
      ]).should eq(true)

      some_hash = Hash(String, HCL::Any).new.tap do |hsh|
        hsh["one"] = HCL::Any.new(1_i64)
        hsh["two"] = HCL::Any.new(2_i64)
        hsh["three"] = HCL::Any.new(3_i64)
      end
      fn.call([
        HCL::Any.new(some_hash),
        HCL::Any.new("two"),
      ]).should eq(true)
    end

    it "raises an error when passed something other than a collection" do
      fn = HCL::Functions::HasIndex.new

      [
        nil,
        123_i64,
        123.456_f64,
        true,
        "hello",
      ].each do |val|
        expect_raises(
          HCL::Function::ArgumentTypeError,
          "hasindex(coll, idx): Argument type mismatch. Expected a collection, but got #{val.class}."
        ) do
          fn.call([
            HCL::Any.new(val),
            HCL::Any.new("doesn't matter"),
          ])
        end
      end
    end

    it "raises an error when passed an incompatible index for the collection" do
      fn = HCL::Functions::HasIndex.new

      arr = Array(HCL::Any).new
      hsh = Hash(String, HCL::Any).new

      expect_raises(
        HCL::Function::ArgumentTypeError,
        "hasindex(coll, idx): Argument type mismatch. Expected a string, but got #{hsh.class}."
      ) do
        fn.call([
          HCL::Any.new(hsh),
          HCL::Any.new(0_i64),
        ])
      end

      expect_raises(
        HCL::Function::ArgumentTypeError,
        "hasindex(coll, idx): Argument type mismatch. Expected a number, but got #{arr.class}."
      ) do
        fn.call([
          HCL::Any.new(arr),
          HCL::Any.new("hello"),
        ])
      end
    end
  end
end
