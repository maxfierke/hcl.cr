require "../../spec_helper"

describe HCL::Functions::Format do
  describe "#matches_arity" do
    it "accepts two to #{HCL::Function::ARG_MAX} arguments" do
      fn = HCL::Functions::Format.new

      fn.matches_arity?(0_u32...1_u32).should eq(false)
      fn.matches_arity?(2_u32...HCL::Function::ARG_MAX).should eq(true)
      fn.matches_arity?(HCL::Function::ARG_MAX + 1).should eq(false)
    end
  end

  describe "#call" do
    it "returns a formatted string" do
      fn = HCL::Functions::Format.new

      fn.call([
        HCL::ValueType.new("hello %s + %s = %s"),
        HCL::ValueType.new("🧄"),
        HCL::ValueType.new("🧇"),
        HCL::ValueType.new("gross")
      ]).value.should eq("hello 🧄 + 🧇 = gross")
    end

    it "raises an error when passed a non-string for fmt parameter" do
      fn = HCL::Functions::Format.new

      expect_raises(
        HCL::Function::ArgumentTypeError,
        "format(fmt, args...): Argument type mismatch. Expected a string, but got Int64."
      ) do
        fn.call([
          HCL::ValueType.new(0_i64),
          HCL::ValueType.new("hello"),
          HCL::ValueType.new("world")
        ])
      end
    end
  end
end
