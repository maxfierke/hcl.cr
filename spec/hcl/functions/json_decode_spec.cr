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
    it "returns a deserialized representation of the value in Any" do
      fn = HCL::Functions::JSONDecode.new

      json = <<-JSON
      {"prop1":123,"prop2":"hello","prop3":{},"prop4":[0,1,2]}
      JSON

      hsh = Hash(String, HCL::Any).new
      hsh["prop1"] = HCL::Any.new(123_i64)
      hsh["prop2"] = HCL::Any.new("hello")
      hsh["prop3"] = HCL::Any.new(Hash(String, HCL::Any).new)
      hsh["prop4"] = HCL::Any.new([
        HCL::Any.new(0_i64),
        HCL::Any.new(1_i64),
        HCL::Any.new(2_i64)
      ])

      deserialized = fn.call([HCL::Any.new(json)])
      deserialized.should eq(HCL::Any.new(hsh))
      deserialized.unwrap.should eq({
        "prop1" => 123_i64,
        "prop2" => "hello",
        "prop3" => {} of String => HCL::Any::RawType,
        "prop4" => [0_i64, 1_i64, 2_i64]
      })
    end
  end
end
