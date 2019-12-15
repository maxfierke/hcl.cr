require "../../spec_helper"

describe HCL::Functions::Int do
  describe "#matches_arity" do
    it "accepts one argument" do
      fn = HCL::Functions::Int.new

      fn.matches_arity?(0_u32).should eq(false)
      fn.matches_arity?(1_u32).should eq(true)
      fn.matches_arity?(2_u32..20_u32).should eq(false)
    end
  end

  describe "#call" do
    it "returns the integer component of a number, rounding towards zero" do
      fn = HCL::Functions::Int.new

      fn.call([
        HCL::ValueType.new(10_i64)
      ]).value.should eq(10_i64)
      fn.call([
        HCL::ValueType.new(-5_i64)
      ]).value.should eq(-5_i64)
      fn.call([
        HCL::ValueType.new(3.12_f64)
      ]).value.should eq(3_i64)
      fn.call([
        HCL::ValueType.new(-18.23_f64)
      ]).value.should eq(-18_i64)
    end
  end
end
