require "./spec_helper"

AnyHash.define_new klass: :TestHash,
  key: Symbol | String,
  value: Number::Primitive

describe AnyHash do
  context ".define_new" do
    it "defines new klass using provided name and K, V types" do
      TestHash.should be_a TestHash.class
    end
    it "returns klass with Key and Value constants" do
      TestHash::Key.should be_a (Symbol | String).class
      TestHash::Value.should be_truthy
    end
    it "defines new klass which inherits from AnyHash" do
      TestHash.should be_a AnyHash(TestHash::Key, TestHash::Value).class
    end
  end

  context ".method_missing" do
    it "defines new method delegator returning self" do
      {% for method in %i(compact! clear) %}
        TestHash.new.{{method.id}}.should be_a TestHash
      {% end %}
    end
    it "defines new method delegator returning self (with block)" do
      {% for method in %i(delete_if reject! select!) %}
        TestHash.new.{{method.id}} { true }.should be_a TestHash
      {% end %}
    end
  end

  context ".deep_cast_value" do
    it "raises TypeCastError when passed invalid type" do
      expect_raises TypeCastError, "cast from Int32 to Bool failed" do
        AnyHash(Symbol, Bool).deep_cast_value 1337.as(Int32 | Bool)
      end
    end
    it "accepts valid type" do
      AnyHash(Symbol, Symbol).deep_cast_value(:foo).should eq(:foo)
    end
  end

  context "#is_a? Enumerable" do
    assert do
      TestHash.new.should be_a(Enumerable({TestHash::Key, TestHash::Value}))
    end
  end

  context "#is_a? Iterable" do
    assert do
      TestHash.new.should be_a(Iterable({TestHash::Key, TestHash::Value}))
    end
  end
end
