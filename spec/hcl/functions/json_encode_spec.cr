require "../../spec_helper"

describe HCL::Functions::JSONEncode do
  describe "#matches_arity" do
    it "accepts one argument" do
      fn = HCL::Functions::JSONEncode.new

      fn.matches_arity?(0_u32).should eq(false)
      fn.matches_arity?(1_u32).should eq(true)
      fn.matches_arity?(2_u32..20_u32).should eq(false)
    end
  end

  describe "#call" do
    it "returns a JSON serialized representation of the value" do
      fn = HCL::Functions::JSONEncode.new

      hsh = Hash(String, HCL::ValueType).new
      hsh["prop1"] = 123_i64
      hsh["prop2"] = "hello"
      hsh["prop3"] = Hash(String, HCL::ValueType).new
      hsh["prop4"] = Array(HCL::ValueType).new.concat([0_i64, 1_i64, 2_i64])

      fn.call([10_i64]).should eq("10")

      fn.call([hsh]).should eq(<<-JSON)
      {"prop1":123,"prop2":"hello","prop3":{},"prop4":[0,1,2]}
      JSON
    end
  end
end
