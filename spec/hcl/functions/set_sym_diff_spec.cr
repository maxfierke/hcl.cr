require "../../spec_helper"

describe HCL::Functions::SetSymDiff do
  describe "#matches_arity" do
    it "accepts two to #{HCL::Function::ARG_MAX} arguments" do
      fn = HCL::Functions::SetSymDiff.new

      fn.matches_arity?(0_u32...1_u32).should eq(false)
      fn.matches_arity?(2_u32...HCL::Function::ARG_MAX).should eq(true)
      fn.matches_arity?(HCL::Function::ARG_MAX + 1).should eq(false)
    end
  end

  describe "#call" do
    it "returns the symmetric difference of all arguments" do
      fn = HCL::Functions::SetSymDiff.new

      arr1 = [
        HCL::Any.new("🧄"),
        HCL::Any.new("🧇"),
      ]
      arr2 = [
        HCL::Any.new("hello"),
        HCL::Any.new(1_i64),
      ]
      arr3 = [
        HCL::Any.new("world"),
        HCL::Any.new(true),
        HCL::Any.new("🧇"),
      ]

      fn.call([
        HCL::Any.new(arr1),
        HCL::Any.new(arr2),
        HCL::Any.new(arr3),
      ]).should eq(["🧄", "hello", 1_i64, "world", true])
    end

    it "raises an error if passed non-array arguments" do
      fn = HCL::Functions::SetSymDiff.new

      expect_raises(
        HCL::Function::ArgumentTypeError,
        "setsymdiff(sets...): Argument type mismatch. Expected an array, but got String"
      ) do
        arr = HCL::Any.new([
          HCL::Any.new("🧄"),
          HCL::Any.new("🧇"),
        ])

        fn.call([arr, HCL::Any.new("hello")])
      end
    end
  end
end
