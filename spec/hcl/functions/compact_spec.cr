require "../../spec_helper"

describe HCL::Functions::Compact do
  describe "#matches_arity" do
    it "accepts one to #{HCL::Function::ARG_MAX} arguments" do
      fn = HCL::Functions::Concat.new

      fn.matches_arity?(0_u32).should eq(false)
      fn.matches_arity?(1_u32...HCL::Function::ARG_MAX).should eq(true)
      fn.matches_arity?(HCL::Function::ARG_MAX + 1).should eq(false)
    end
  end

  describe "#call" do
    it "returns the non-null arguments" do
      fn = HCL::Functions::Compact.new

      hsh = Hash(String, HCL::ValueType).new
      arr = Array(HCL::ValueType).new

      fn.call([
        HCL::ValueType.new(hsh),
        HCL::ValueType.new(nil),
        HCL::ValueType.new("hello")
      ]).raw.should eq([
        HCL::ValueType.new(hsh),
        HCL::ValueType.new("hello")
      ])
      fn.call([
        HCL::ValueType.new(arr),
        HCL::ValueType.new(nil)
      ]).raw.should eq([
        HCL::ValueType.new(arr)
      ])
      fn.call([
        HCL::ValueType.new(nil),
        HCL::ValueType.new("🧄"),
        HCL::ValueType.new("🧇")
      ]).raw.should eq([
        HCL::ValueType.new("🧄"),
        HCL::ValueType.new("🧇")
      ])

      fn.call([
        HCL::ValueType.new(nil),
        HCL::ValueType.new(nil)
      ]).raw.should eq(Array(HCL::ValueType).new)

      some_hash = Hash(String, HCL::ValueType).new.tap do |hsh|
        hsh["one"] = HCL::ValueType.new(1_i64)
        hsh["two"] = HCL::ValueType.new(2_i64)
        hsh["three"] = HCL::ValueType.new(3_i64)
      end
      fn.call([
        HCL::ValueType.new(nil),
        HCL::ValueType.new(some_hash)
      ]).raw.should eq([
        HCL::ValueType.new(some_hash)
      ])
    end
  end
end
