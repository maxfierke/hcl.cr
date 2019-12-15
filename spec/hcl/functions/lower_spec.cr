require "../../spec_helper"

describe HCL::Functions::Lower do
  describe "#matches_arity" do
    it "accepts one argument" do
      fn = HCL::Functions::Lower.new

      fn.matches_arity?(0_u32).should eq(false)
      fn.matches_arity?(1_u32).should eq(true)
      fn.matches_arity?(2_u32..20_u32).should eq(false)
    end
  end

  describe "#call" do
    it "returns lower variant of string" do
      fn = HCL::Functions::Lower.new

      fn.call(["WHISPER"]).should eq("whisper")
      fn.call(["already_lower"]).should eq("already_lower")
    end

    it "raises an error when passed something other than a string" do
      fn = HCL::Functions::Lower.new

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
          "lower(str): Argument type mismatch. Expected a string, but got #{val.class}."
        ) do
          fn.call([val.as(HCL::ValueType)])
        end
      end
    end
  end
end
