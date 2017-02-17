require "../../spec_helper"

private class TestObject
  any_json_property :user
  any_json_property :tags, :context
end

describe Object do
  describe ".any_json_property" do
    {% for property in %i(tags user context) %}
      it "defines lazily initialized instance getter {{property}} with type AnyHash::JSON" do
        obj = TestObject.new
        obj.@{{property.id}}.should be_nil
        obj.{{property.id}}.should be_a(AnyHash::JSON)
      end

      it "defines instance setter {{property}} (AnyHash::JSON)" do
        obj, any_hash = TestObject.new, AnyHash::JSON{:foo => :bar}
        obj.{{property.id}} = any_hash
        obj.{{property.id}}.should be(any_hash)
      end

      it "defines instance setter {{property}} (Hash | NamedTuple)" do
        obj = TestObject.new
        obj.{{property.id}} = {:flags => {:red, :green, :blue}}
        obj.{{property.id}} = {flags: {:red, :green, :blue}}
        obj.{{property.id}}.should eq({flags: [:red, :green, :blue]})
      end
    {% end %}
  end
end

describe Hash do
  describe "#to_any_json" do
    it "returns self wrapped in AnyHash" do
      hash = {:foo => :bar, :ints => [1, 2, 3, :four]}
      any_json = hash.to_any_json
      any_json.should be_a(AnyHash::JSON)
      any_json.should eq(hash)
      any_json.fetch(:foo).should eq(:bar)
    end
  end
end

describe NamedTuple do
  describe "#to_any_json" do
    it "returns self wrapped in AnyHash" do
      options = {foo: :bar, ints: [1, 2, 3, :four]}
      any_json = options.to_any_json
      any_json.should be_a(AnyHash::JSON)
      any_json.should eq(options)
      any_json.fetch(:foo).should eq(:bar)
    end
  end
end
