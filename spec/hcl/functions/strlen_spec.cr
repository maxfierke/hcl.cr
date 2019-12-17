require "../../spec_helper"

describe HCL::Functions::Strlen do
  describe "#matches_arity" do
    it "accepts one argument" do
      fn = HCL::Functions::Strlen.new

      fn.matches_arity?(0_u32).should eq(false)
      fn.matches_arity?(1_u32).should eq(true)
      fn.matches_arity?(2_u32..20_u32).should eq(false)
    end
  end

  describe "#call" do
    it "returns the character length in Unicode graphemes" do
      fn = HCL::Functions::Strlen.new

      fn.call([HCL::ValueType.new("")]).raw.should eq(0)
      fn.call([HCL::ValueType.new("string")]).raw.should eq(6)
      fn.call([HCL::ValueType.new("🧄🧇")]).raw.should eq(2)
    end

    it "raises an error when passed something other than a string" do
      fn = HCL::Functions::Strlen.new

      [
        nil,
        123_i64,
        123.456_f64,
        true,
        Hash(String, HCL::ValueType).new,
        Array(HCL::ValueType).new
      ].each do |val|
        expect_raises(
          HCL::Function::ArgumentTypeError,
          "strlen(str): Argument type mismatch. Expected a string, but got #{val.class}."
        ) do
          fn.call([HCL::ValueType.new(val)])
        end
      end
    end
  end
end
