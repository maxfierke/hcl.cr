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
        "🧄".as(HCL::ValueType),
        "🧇".as(HCL::ValueType)
      ]
      arr2 = [
        "hello".as(HCL::ValueType),
        1_i64.as(HCL::ValueType)
      ]

      fn.call(Array(HCL::ValueType).new).should eq(Array(HCL::ValueType).new)
      fn.call([arr1, arr2]).should eq(["🧄", "🧇", "hello", 1_i64])
    end

    it "raises an error if passed non-array arguments" do
      fn = HCL::Functions::Concat.new

      expect_raises(
        HCL::Function::ArgumentTypeError,
        "concat(seqs...): Argument type mismatch. Expected an array, but got String"
      ) do
        arr = [
          "🧄".as(HCL::ValueType),
          "🧇".as(HCL::ValueType)
        ]

        fn.call([arr, "hello"])
      end
    end
  end
end
