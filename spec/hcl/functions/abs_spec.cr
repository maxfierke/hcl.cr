require "../../spec_helper"

describe HCL::Functions::Abs do
  describe "#matches_arity" do
    it "accepts one argument" do
      fn = HCL::Functions::Abs.new

      fn.matches_arity?(0_u32).should eq(false)
      fn.matches_arity?(1_u32).should eq(true)
      fn.matches_arity?(2_u32..20_u32).should eq(false)
    end
  end

  describe "#call" do
    it "returns correct absolute value" do
      fn = HCL::Functions::Abs.new

      fn.call([
        HCL::ValueType.new(10_i64)
      ]).raw.should eq(10_i64)
      fn.call([
        HCL::ValueType.new(-5_i64)
      ]).raw.should eq(5_i64)
      fn.call([
        HCL::ValueType.new(3.12_f64)
      ]).raw.should eq(3.12_f64)
      fn.call([
        HCL::ValueType.new(-18.23_f64)
      ]).raw.should eq(18.23_f64)
    end
  end
end
