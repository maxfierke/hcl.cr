require "../../spec_helper"

describe HCL::Functions::SetSubtract do
  describe "#matches_arity" do
    it "accepts two arguments" do
      fn = HCL::Functions::SetSubtract.new

      fn.matches_arity?(0_u32...1_u32).should eq(false)
      fn.matches_arity?(2_u32).should eq(true)
      fn.matches_arity?(3_u32..20_u32).should eq(false)
    end
  end

  describe "#call" do
    it "returns a set with the elements found in the first but not the second" do
      fn = HCL::Functions::SetSubtract.new

      arr1 = [
        HCL::Any.new("🧄"),
        HCL::Any.new("🧇")
      ]
      arr2 = [
        HCL::Any.new("hello"),
        HCL::Any.new(1_i64),
        HCL::Any.new("🧇")
      ]

      fn.call([
        HCL::Any.new(arr1),
        HCL::Any.new(arr2),
      ]).should eq(["🧄"])
    end

    it "raises an error if passed non-array arguments" do
      fn = HCL::Functions::SetSubtract.new

      expect_raises(
        HCL::Function::ArgumentTypeError,
        "setsubtract(set1, set2): Argument type mismatch. Expected an array, but got String"
      ) do
        arr = HCL::Any.new([
          HCL::Any.new("🧄"),
          HCL::Any.new("🧇")
        ])

        fn.call([arr, HCL::Any.new("hello")])
      end
    end
  end
end
