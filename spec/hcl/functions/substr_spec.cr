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
        HCL::Any.new("hello world"),
        HCL::Any.new(6_i64),
        HCL::Any.new(5_i64)
      ]).should eq("world")
    end

    it "raises an error when passed something other than a string for first arg" do
      fn = HCL::Functions::Substr.new

      [
        nil,
        123_i64,
        123.456_f64,
        true,
        Hash(String, HCL::Any).new,
        Array(HCL::Any).new
      ].each do |val|
        expect_raises(
          HCL::Function::ArgumentTypeError,
          "substr(str, offset, length): Argument type mismatch. Expected a string, but got #{val.class}."
        ) do
          fn.call([HCL::Any.new(val), HCL::Any.new(0_i64), HCL::Any.new(0_i64)])
        end
      end
    end

    it "raises an error when passed something other than a number for second arg" do
      fn = HCL::Functions::Substr.new

      [
        nil,
        "hello",
        true,
        Hash(String, HCL::Any).new,
        Array(HCL::Any).new
      ].each do |val|
        expect_raises(
          HCL::Function::ArgumentTypeError,
          "substr(str, offset, length): Argument type mismatch. Expected an integer, but got #{val.class}."
        ) do
          fn.call([HCL::Any.new("hello"), HCL::Any.new(val), HCL::Any.new(99_i64)])
        end
      end
    end

    it "raises an error when passed something other than an integer for third arg" do
      fn = HCL::Functions::Substr.new

      [
        nil,
        "hello",
        true,
        Hash(String, HCL::Any).new,
        Array(HCL::Any).new
      ].each do |val|
        expect_raises(
          HCL::Function::ArgumentTypeError,
          "substr(str, offset, length): Argument type mismatch. Expected an integer, but got #{val.class}."
        ) do
          fn.call([HCL::Any.new("hello"), HCL::Any.new(0_i64), HCL::Any.new(val)])
        end
      end
    end
  end
end
