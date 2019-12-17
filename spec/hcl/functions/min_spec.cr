require "../../spec_helper"

describe HCL::Functions::Min do
  describe "#matches_arity" do
    it "accepts one to #{HCL::Function::ARG_MAX} arguments" do
      fn = HCL::Functions::Concat.new

      fn.matches_arity?(0_u32).should eq(false)
      fn.matches_arity?(1_u32...HCL::Function::ARG_MAX).should eq(true)
      fn.matches_arity?(HCL::Function::ARG_MAX + 1).should eq(false)
    end
  end

  describe "#call" do
    it "returns array concatenating all array arguments" do
      fn = HCL::Functions::Min.new

      arr = [
        HCL::ValueType.new(-1_i64),
        HCL::ValueType.new(38_i64),
        HCL::ValueType.new(0_i64)
      ]

      fn.call(arr).raw.should eq(-1)
    end

    it "raises an error when passed an empty array" do
      fn = HCL::Functions::Min.new

      expect_raises(
        HCL::Function::FunctionArgumentError,
        "min(numbers...): Received empty array. Expected at least one element."
      ) do
        fn.call(Array(HCL::ValueType).new)
      end
    end

    it "raises an error when passed an array with non-numbers" do
      fn = HCL::Functions::Min.new

      expect_raises(
        HCL::Function::ArgumentTypeError,
        "min(numbers...): Argument type mismatch. Expected array of only numbers."
      ) do
        fn.call([
          HCL::ValueType.new(1_i64),
          HCL::ValueType.new("hello")
        ])
      end
    end
  end
end
