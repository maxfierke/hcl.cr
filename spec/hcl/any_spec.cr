require "../spec_helper"

describe HCL::Any do
  describe "casts" do
    it "gets nil" do
      HCL::Any.new(nil).as_nil.should be_nil
    end

    it "gets bool" do
      HCL::Any.new(true).as_bool.should be_true
      HCL::Any.new(false).as_bool.should be_false
      HCL::Any.new(true).as_bool?.should be_true
      HCL::Any.new(false).as_bool?.should be_false
      HCL::Any.new(2_i64).as_bool?.should be_nil
    end

    it "gets int64" do
      HCL::Any.new(123456789123456_i64).as_i.should eq(123456789123456_i64)
      HCL::Any.new(123456789123456_i64).as_i?.should eq(123456789123456_i64)
      HCL::Any.new(true).as_i?.should be_nil
    end

    it "gets float64" do
      HCL::Any.new(123.45_f64).as_f.should eq(123.45_f64)
      HCL::Any.new(123.45_f64).as_f?.should eq(123.45_f64)
      HCL::Any.new(true).as_f?.should be_nil
    end

    it "gets string" do
      HCL::Any.new("hello").as_s.should eq("hello")
      HCL::Any.new("hello").as_s?.should eq("hello")
      HCL::Any.new(true).as_s?.should be_nil
    end

    it "gets array" do
      HCL::Any.new([1_i64, 2_i64, 3_i64]).as_a.should eq([1_i64, 2_i64, 3_i64])
      HCL::Any.new([1_i64, 2_i64, 3_i64]).as_a?.should eq([1_i64, 2_i64, 3_i64])
      HCL::Any.new(true).as_a?.should be_nil
    end

    it "gets hash" do
      HCL::Any.new({"foo" => "bar"}).as_h.should eq({"foo" => "bar"})
      HCL::Any.new({"foo" => "bar"}).as_h?.should eq({"foo" => "bar"})
      HCL::Any.new(true).as_h?.should be_nil
    end
  end

  describe "#size" do
    it "of array" do
      HCL::Any.new([1_i64, 2_i64, 3_i64]).size.should eq(3)
    end

    it "of hash" do
      HCL::Any.new({"foo" => "bar"}).size.should eq(1)
    end
  end

  describe "#[]" do
    it "of array" do
      HCL::Any.new([1_i64, 2_i64, 3_i64])[1].raw.should eq(2)
    end

    it "of hash" do
      HCL::Any.new({"foo" => "bar"})["foo"].raw.should eq("bar")
    end
  end

  describe "#[]?" do
    it "of array" do
      HCL::Any.new([1_i64, 2_i64, 3_i64])[1]?.not_nil!.raw.should eq(2)
      HCL::Any.new([1_i64, 2_i64, 3_i64])[3]?.should be_nil
      HCL::Any.new([true, false])[1]?.should eq false
    end

    it "of hash" do
      HCL::Any.new({"foo" => "bar"})["foo"]?.not_nil!.raw.should eq("bar")
      HCL::Any.new({"foo" => "bar"})["fox"]?.should be_nil
      HCL::Any.new({"foo" => false})["foo"]?.should eq false
    end
  end

  describe "#dig?" do
    it "gets the value at given path given splat" do
      obj = HCL::Any.new({
        "foo" => HCL::Any.new([
          HCL::Any.new(1_i64),
          HCL::Any.new({"bar" => [2_i64, 3_i64]}),
        ]),
      })

      obj.dig?("foo", 0).should eq(1_i64)
      obj.dig?("foo", 1, "bar", 1).should eq(3_i64)
    end

    it "returns nil if not found" do
      obj = HCL::Any.new({
        "foo" => HCL::Any.new([
          HCL::Any.new(1_i64),
          HCL::Any.new({"bar" => [2_i64, 3_i64]}),
        ]),
      })

      obj.dig?("foo", 10).should be_nil
      obj.dig?("bar", "baz").should be_nil
      obj.dig?("").should be_nil
    end

    it "returns nil for non-Hash/Array intermediary values" do
      HCL::Any.new(nil).dig?("foo").should be_nil
      HCL::Any.new(0.0_f64).dig?("foo").should be_nil
    end
  end

  describe "dig" do
    it "gets the value at given path given splat" do
      obj = HCL::Any.new({
        "foo" => HCL::Any.new([
          HCL::Any.new(1_i64),
          HCL::Any.new({"bar" => [2_i64, 3_i64]}),
        ]),
      })

      obj.dig("foo", 0).should eq(1_i64)
      obj.dig("foo", 1, "bar", 1).should eq(3_i64)
    end

    it "raises if not found" do
      obj = HCL::Any.new({
        "foo" => HCL::Any.new([
          HCL::Any.new(1_i64),
          HCL::Any.new({"bar" => [2_i64, 3_i64]}),
        ]),
      })

      expect_raises Exception, %(Expected Hash for #[](key : String), not Array(HCL::Any)) do
        obj.dig("foo", 1, "bar", "baz")
      end
      expect_raises KeyError, %(Missing hash key: "z") do
        obj.dig("z")
      end
      expect_raises KeyError, %(Missing hash key: "") do
        obj.dig("")
      end
    end
  end

  it "traverses big structure" do
    obj = HCL::Any.new({
      "foo" => HCL::Any.new([
        HCL::Any.new(1_i64),
        HCL::Any.new({"bar" => [2_i64, 3_i64]}),
      ]),
    })
    obj["foo"][1]["bar"][1].as_i.should eq(3_i64)
  end

  it "compares to other objects" do
    obj = HCL::Any.new([1_i64, 2_i64])
    obj.should eq([1_i64, 2_i64])
    obj[0].should eq(1_i64)
  end

  it "can compare with ===" do
    (1_i64 === HCL::Any.new(1_i64)).should be_truthy
  end

  it "dups" do
    any = HCL::Any.new([1_i64, 2_i64, 3_i64])
    any2 = any.dup
    any2.as_a.should_not be(any.as_a)
  end

  it "clones" do
    any = HCL::Any.new([
      HCL::Any.new([1_i64]),
      HCL::Any.new(2_i64),
      HCL::Any.new(3_i64),
    ])
    any2 = any.clone
    any2.as_a[0].as_a.should_not be(any.as_a[0].as_a)
  end
end
