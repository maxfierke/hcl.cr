require "../../spec_helper"

describe HCL::Functions::SetHas do
  describe "#matches_arity" do
    it "accepts one argument" do
      fn = HCL::Functions::SetHas.new

      fn.matches_arity?(0_u32..1_u32).should eq(false)
      fn.matches_arity?(2_u32).should eq(true)
      fn.matches_arity?(3_u32..20_u32).should eq(false)
    end
  end

  describe "#call" do
    it "returns the whether the value exists in the set" do
      fn = HCL::Functions::SetHas.new

      fn.call([
        HCL::Any.new(Array(HCL::Any).new),
        HCL::Any.new(99_i64),
      ]).should eq(false)
      fn.call([
        HCL::Any.new([
          HCL::Any.new("🧄"),
          HCL::Any.new("🧇"),
        ]),
        HCL::Any.new("🧇"),
      ]).should eq(true)
    end

    it "raises an error when passed something other than a collection" do
      fn = HCL::Functions::SetHas.new

      [
        nil,
        123_i64,
        123.456_f64,
        true,
        "hello",
        Hash(String, HCL::Any).new,
      ].each do |val|
        expect_raises(
          HCL::Function::ArgumentTypeError,
          "sethas(set, val): Argument type mismatch. Expected a set, but got #{val.class}."
        ) do
          fn.call([
            HCL::Any.new(val),
            HCL::Any.new("doesn't matter"),
          ])
        end
      end
    end
  end
end
