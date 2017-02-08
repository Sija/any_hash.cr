require "./spec_helper"

describe AnyHash do
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
end

require "./any_hash/*"
