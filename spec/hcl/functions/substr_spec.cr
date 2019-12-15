require "../../spec_helper"

describe HCL::Functions::Substr do
  describe "#matches_arity" do
    it "accepts three arguments" do
      fn = HCL::Functions::Substr.new

      fn.matches_arity?(0_u32..2_u32).should eq(false)
      fn.matches_arity?(3_u32).should eq(true)
      fn.matches_arity?(4_u32..20_u32).should eq(false)
    end
  end

  describe "#call" do
    it "returns the expected substring" do
      fn = HCL::Functions::Substr.new

      fn.call([
        HCL::ValueType.new("hello world"),
        HCL::ValueType.new(6_i64),
        HCL::ValueType.new(5_i64)
      ]).value.should eq("world")
    end

    it "raises an error when passed something other than a string for first arg" do
      fn = HCL::Functions::Substr.new

      [
        nil,
        123_i64,
        123.456_f64,
        true,
        Hash(String, HCL::ValueType).new,
        Array(HCL::ValueType).new
      ].map { |val| HCL::ValueType.new(val) }.each do |val|
        expect_raises(
          HCL::Function::ArgumentTypeError,
          "substr(str, offset, length): Argument type mismatch. Expected a string, but got #{val.value.class}."
        ) do
          fn.call([val, HCL::ValueType.new(0_i64), HCL::ValueType.new(0_i64)])
        end
      end
    end

    it "raises an error when passed something other than a number for second arg" do
      fn = HCL::Functions::Substr.new

      [
        nil,
        "hello",
        true,
        Hash(String, HCL::ValueType).new,
        Array(HCL::ValueType).new
      ].map { |val| HCL::ValueType.new(val) }.each do |val|
        expect_raises(
          HCL::Function::ArgumentTypeError,
          "substr(str, offset, length): Argument type mismatch. Expected an integer, but got #{val.value.class}."
        ) do
          fn.call([HCL::ValueType.new("hello"), val, HCL::ValueType.new(99_i64)])
        end
      end
    end

    it "raises an error when passed something other than an integer for third arg" do
      fn = HCL::Functions::Substr.new

      [
        nil,
        "hello",
        true,
        Hash(String, HCL::ValueType).new,
        Array(HCL::ValueType).new
      ].map { |val| HCL::ValueType.new(val) }.each do |val|
        expect_raises(
          HCL::Function::ArgumentTypeError,
          "substr(str, offset, length): Argument type mismatch. Expected an integer, but got #{val.value.class}."
        ) do
          fn.call([HCL::ValueType.new("hello"), HCL::ValueType.new(0_i64), val])
        end
      end
    end
  end
end
