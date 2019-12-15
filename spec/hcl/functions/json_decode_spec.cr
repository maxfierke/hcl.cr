require "../../spec_helper"

describe HCL::Functions::JSONDecode do
  describe "#matches_arity" do
    it "accepts one argument" do
      fn = HCL::Functions::JSONDecode.new

      fn.matches_arity?(0_u32).should eq(false)
      fn.matches_arity?(1_u32).should eq(true)
      fn.matches_arity?(2_u32..20_u32).should eq(false)
    end
  end

  describe "#call" do
    pending "returns a deserialized representation of the value in Crystal types" do
      fn = HCL::Functions::JSONDecode.new

      json = <<-JSON
      {"prop1":123,"prop2":"hello","prop3":{},"prop4":[0,1,2]}
      JSON

      hsh = Hash(String, HCL::ValueType).new
      hsh["prop1"] = 123_i64
      hsh["prop2"] = "hello"
      hsh["prop3"] = Hash(String, HCL::ValueType).new
      hsh["prop4"] = Array(HCL::ValueType).new.concat([0_i64, 1_i64, 2_i64])

      fn.call(["10"]).should eq(10_i64)
      fn.call([json]).should eq(hsh)
    end
  end
end
