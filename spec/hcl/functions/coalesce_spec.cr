require "../../spec_helper"

describe HCL::Functions::Coalesce do
  describe "#matches_arity" do
    it "accepts one to #{HCL::Function::ARG_MAX} arguments" do
      fn = HCL::Functions::Concat.new

      fn.matches_arity?(0_u32).should eq(false)
      fn.matches_arity?(1_u32...HCL::Function::ARG_MAX).should eq(true)
      fn.matches_arity?(HCL::Function::ARG_MAX + 1).should eq(false)
    end
  end

  describe "#call" do
    it "returns the first non-null argument" do
      fn = HCL::Functions::Coalesce.new

      hsh = Hash(String, HCL::Any).new
      arr = Array(HCL::Any).new

      fn.call([
        HCL::Any.new(hsh),
        HCL::Any.new("hello")
      ]).should eq(hsh)
      fn.call([
        HCL::Any.new(arr),
        HCL::Any.new(nil)
      ]).should eq(arr)
      fn.call([
        HCL::Any.new(nil),
        HCL::Any.new("🧄"),
        HCL::Any.new("🧇")
      ]).should eq("🧄")

      fn.call([
        HCL::Any.new(nil),
        HCL::Any.new(nil),
        HCL::Any.new(nil)
      ]).should eq(nil)

      some_hash = Hash(String, HCL::Any).new.tap do |hsh|
        hsh["one"] = HCL::Any.new(1_i64)
        hsh["two"] = HCL::Any.new(2_i64)
        hsh["three"] = HCL::Any.new(3_i64)
      end
      fn.call([
        HCL::Any.new(nil),
        HCL::Any.new(some_hash)
      ]).should eq(some_hash)
    end
  end
end
