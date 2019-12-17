require "../../spec_helper"

describe HCL::Functions::Length do
  describe "#matches_arity" do
    it "accepts one argument" do
      fn = HCL::Functions::Length.new

      fn.matches_arity?(0_u32).should eq(false)
      fn.matches_arity?(1_u32).should eq(true)
      fn.matches_arity?(2_u32..20_u32).should eq(false)
    end
  end

  describe "#call" do
    it "returns the length of the collection" do
      fn = HCL::Functions::Length.new

      fn.call([
        HCL::Any.new(Hash(String, HCL::Any).new)
      ]).should eq(0)
      fn.call([
        HCL::Any.new(Array(HCL::Any).new)
      ]).should eq(0)
      fn.call([
        HCL::Any.new([
          HCL::Any.new("🧄"),
          HCL::Any.new("🧇")
        ])
      ]).should eq(2)

      some_hash = Hash(String, HCL::Any).new.tap do |hsh|
        hsh["one"] = HCL::Any.new(1_i64)
        hsh["two"] = HCL::Any.new(2_i64)
        hsh["three"] = HCL::Any.new(3_i64)
      end
      fn.call([
        HCL::Any.new(some_hash)
      ]).should eq(3)
    end

    it "raises an error when passed something other than a collection" do
      fn = HCL::Functions::Length.new

      [
        nil,
        123_i64,
        123.456_f64,
        true,
        "hello",
      ].each do |val|
        expect_raises(
          HCL::Function::ArgumentTypeError,
          "length(coll): Argument type mismatch. Expected a collection, but got #{val.class}."
        ) do
          fn.call([
            HCL::Any.new(val)
          ])
        end
      end
    end
  end
end
