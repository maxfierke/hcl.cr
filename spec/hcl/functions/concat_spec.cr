require "../../spec_helper"

describe HCL::Functions::Concat do
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
      fn = HCL::Functions::Concat.new

      arr1 = [
        HCL::Any.new("🧄"),
        HCL::Any.new("🧇"),
      ]
      arr2 = [
        HCL::Any.new("hello"),
        HCL::Any.new(1_i64),
      ]

      fn.call(Array(HCL::Any).new).should eq(Array(HCL::Any).new)
      fn.call([
        HCL::Any.new(arr1),
        HCL::Any.new(arr2),
      ]).should eq([
        HCL::Any.new("🧄"),
        HCL::Any.new("🧇"),
        HCL::Any.new("hello"),
        HCL::Any.new(1_i64),
      ])
    end

    it "raises an error if passed non-array arguments" do
      fn = HCL::Functions::Concat.new

      expect_raises(
        HCL::Function::ArgumentTypeError,
        "concat(seqs...): Argument type mismatch. Expected an array, but got String"
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
