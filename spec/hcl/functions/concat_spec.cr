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
        HCL::ValueType.new("🧄"),
        HCL::ValueType.new("🧇")
      ]
      arr2 = [
        HCL::ValueType.new("hello"),
        HCL::ValueType.new(1_i64)
      ]

      fn.call(Array(HCL::ValueType).new).value.should eq(Array(HCL::ValueType).new)
      fn.call([
        HCL::ValueType.new(arr1),
        HCL::ValueType.new(arr2)
      ]).value.should eq([
        HCL::ValueType.new("🧄"),
        HCL::ValueType.new("🧇"),
        HCL::ValueType.new("hello"),
        HCL::ValueType.new(1_i64)
      ])
    end

    it "raises an error if passed non-array arguments" do
      fn = HCL::Functions::Concat.new

      expect_raises(
        HCL::Function::ArgumentTypeError,
        "concat(seqs...): Argument type mismatch. Expected an array, but got String"
      ) do
        arr = HCL::ValueType.new([
          HCL::ValueType.new("🧄"),
          HCL::ValueType.new("🧇")
        ])

        fn.call([arr, HCL::ValueType.new("hello")])
      end
    end
  end
end
