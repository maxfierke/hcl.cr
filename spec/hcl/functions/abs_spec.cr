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
        HCL::Any.new(10_i64)
      ]).should eq(10_i64)
      fn.call([
        HCL::Any.new(-5_i64)
      ]).should eq(5_i64)
      fn.call([
        HCL::Any.new(3.12_f64)
      ]).should eq(3.12_f64)
      fn.call([
        HCL::Any.new(-18.23_f64)
      ]).should eq(18.23_f64)
    end
  end
end
