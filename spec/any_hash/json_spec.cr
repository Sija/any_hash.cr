require "../spec_helper"

describe AnyHash::JSON do
  context ".deep_cast_value" do
    valid_values = {nil, 1, 2_i64, 13.37, true, :foo, "bar", Time.now}

    it "raises TypeCastError when passed invalid type" do
      expect_raises TypeCastError, /cast from Slice\(UInt8\) to .*? failed/ do
        AnyHash::JSON.deep_cast_value Bytes.empty.as(Bytes | Int64)
      end
      expect_raises TypeCastError, /cast from Char to .*? failed/ do
        AnyHash::JSON.deep_cast_value 'a'.as(Char | String)
      end
    end

    it "accepts valid JSON type" do
      valid_values.each do |v|
        AnyHash::JSON.deep_cast_value(v).should eq(v)
      end
    end

    it "converts Tuple to an Array" do
      AnyHash::JSON.deep_cast_value({1, 2, 3}).should eq([1, 2, 3])
    end

    it "converts Tuple to an Array (recursive)" do
      AnyHash::JSON.deep_cast_value({ { {1, 2, 3} } }).should eq([[[1, 2, 3]]])
    end

    it "converts NamedTuple to a Hash" do
      AnyHash::JSON.deep_cast_value({foo: true, bar: 1337})
                   .should eq({:foo => true, :bar => 1337})
    end

    it "converts NamedTuple to a Hash (recursive)" do
      AnyHash::JSON.deep_cast_value({foo: {jazz: true, swing: :always}, bar: 1337})
                   .should eq({:foo => {:jazz => true, :swing => :always}, :bar => 1337})
    end

    it "accepts valid JSON type (recursive)" do
      recursive_values = {
        [[[valid_values.to_a]]],
        { { {valid_values} } },
        [{[valid_values]}],
        tuple = {named: :tuple, powers: {types: true}},
        {:good => "hash", :bad => tuple},
      }
      recursive_values.each do |v|
        AnyHash::JSON.deep_cast_value(v).should be_truthy
      end
    end
  end

  context ".deep_merge!" do
    it "merges given Hash with another AnyHash::JSON, Hash or NamedTuple" do
      hash = {} of AnyHash::JSON::Key => AnyHash::JSON::Value

      AnyHash::JSON.deep_merge!(hash, *{
        AnyHash::JSON.new({foo: {bar: true}}),
        {:foo => {swing: 133.7}},
        {foo: {jazz: "60s"}},
        {foo: {roar: {} of Symbol => Symbol}},
        {:foo => {roar: {"alfa" => "beta"}}},
      }).should eq(hash)

      hash.should eq({
        :foo => {:bar => true, :swing => 133.7, :jazz => "60s", :roar => {"alfa" => "beta"}},
      })
    end
  end

  context "#initialize" do
    it "raises TypeCastError when passed invalid type" do
      expect_raises TypeCastError, /cast from Slice\(UInt8\) to .*? failed/ do
        AnyHash::JSON.new({invalid: Bytes.empty.as(Bytes | Int64)})
      end
      expect_raises TypeCastError, /cast from Char to .*? failed/ do
        AnyHash::JSON.new({why_oh_why_i_did_not_call_to_s: 'a'.as(Char | String)})
      end
    end

    it "takes another AnyHash::JSON, Hash or NamedTuple as an initial value" do
      AnyHash::JSON.new(AnyHash::JSON.new({foo: {bar: true}}))
                   .to_h.should eq({:foo => {:bar => true}})
      AnyHash::JSON.new({foo: {bar: true}})
                   .to_h.should eq({:foo => {:bar => true}})
      AnyHash::JSON.new({:foo => {:bar => true}})
                   .to_h.should eq({:foo => {:bar => true}})
    end

    it "takes another AnyHash::JSON or Hash by reference" do
      samples = {
        AnyHash::JSON.new({kung: :foo}),
        {:kung => :foo} of AnyHash::JSON::Key => AnyHash::JSON::Value,
      }

      samples.each do |hash|
        another = AnyHash::JSON.new(hash)
        another.should eq(hash)

        another.merge!({foo: :mare, bar: 10, drink: true})
        another.should eq(hash)

        {hash[:foo]?, another[:foo]?}.should eq({:mare, :mare})
      end
    end
  end

  context "#dup" do
    it "returns shallow copy of the self" do
      hash = AnyHash::JSON.new({foo: {bar: true}})
      other = hash.dup.merge! jazz: {swing: true}

      other.dig?(:jazz, :swing).should eq(true)
      hash.dig?(:jazz, :swing).should be_nil

      # other.merge! foo: {bar: :baz}
      # hash.dig?(:foo, :bar).should eq(:baz)
    end
  end

  context "#clone" do
    it "returns deep copy of the self" do
      hash = AnyHash::JSON.new({foo: {bar: {baz: {bat: {eat_fruits: true}}}}})
      other = hash.clone.merge! jazz: {swing: true}

      other.dig?(:jazz, :swing).should eq(true)
      hash.dig?(:jazz, :swing).should be_nil

      other.merge! foo: {bar: {baz: {bat: {eat_fruits: false}}}}
      hash.dig?(:foo, :bar, :baz, :bat, :eat_fruits).should eq(true)
    end
  end

  context "#==" do
    samples = {
      eq:  {AnyHash::JSON.new({foo: 1337}), {foo: 1337_i64}, {:foo => 1337}},
      neq: {AnyHash::JSON.new({json: :jmom}), {foo: false}, {"bar" => "fly"}},
    }

    it "compares keys and values of AnyHash::JSON, Hash or NamedTuple" do
      samples[:eq].in_groups_of(2, samples[:eq].last).each do |(hash, another)|
        (hash == another).should be_true
      end
      samples[:neq].in_groups_of(2, samples[:neq].first).each do |(hash, another)|
        (hash == another).should be_false
      end
    end
  end

  context "#[]?" do
    hash = AnyHash::JSON.new({foo: {jazz: "60s"}, oof: true, zilch: nil})

    it "returns nil if value is missing" do
      hash[:foo, :swing]?.should be_nil
      hash[:bar, :foo]?.should be_nil
    end
    it "extracts the nested value" do
      hash[:foo]?.should eq({:jazz => "60s"})
      hash[:foo, :jazz]?.should eq("60s")
    end
  end

  context "#[]" do
    hash = AnyHash::JSON.new({foo: {jazz: "60s"}, oof: true, zilch: nil})

    it "raises if value is missing" do
      expect_raises { hash.dig(:foo, :swing) }
      expect_raises { hash.dig(:bar, :foo) }
      expect_raises { hash.dig(:foo, :jazz, :blues) }
      expect_raises { hash.dig(:oof, :foo) }
    end
    it "extracts the nested value" do
      hash[:foo].should eq({:jazz => "60s"})
      hash[:foo, :jazz].should eq("60s")
    end
  end

  context "#[]=(*args)" do
    it "writes under the given nested key" do
      hash = AnyHash::JSON.new({foo: {jazz: "60s"}})
      (hash[:foo, :jazz] = :bar).should eq(:bar)
      hash.should eq({foo: {jazz: :bar}})
    end
    it "overwrites the given nested key" do
      hash = AnyHash::JSON.new({foo: {jazz: "60s"}})
      (hash[:foo, :jazz] = :bar).should eq(:bar)
      hash.should eq({foo: {jazz: :bar}})
    end
  end

  context "#dig?" do
    hash = AnyHash::JSON.new({foo: {jazz: "60s"}, oof: true, zilch: nil})

    it "returns nil if intermediate value is missing" do
      hash.dig?(:foo, :swing).should be_nil
      hash.dig?(:bar, :foo).should be_nil
    end
    it "returns nil if intermediate value is not a Hash" do
      hash.dig?(:foo, :jazz, :blues).should be_nil
      hash.dig?(:oof, :foo).should be_nil
    end

    it "extracts the nested value" do
      hash.dig?(:foo).should eq({:jazz => "60s"})
      hash.dig?(:foo, :jazz).should eq("60s")
    end
    it "extracts the nested nil value" do
      hash.dig?(:zilch).should be_nil
    end
  end

  context "#dig" do
    hash = AnyHash::JSON.new({foo: {jazz: "60s"}, oof: true, zilch: nil})

    it "raises if intermediate value is missing" do
      expect_raises KeyError, "Missing hash key: :swing" do
        hash.dig(:foo, :swing)
      end
      expect_raises KeyError, "Missing hash key: :bar" do
        hash.dig(:bar, :foo)
      end
    end
    it "raises if intermediate value is not a Hash" do
      expect_raises TypeCastError, /cast from String to Hash\(.*?\) failed/ do
        hash.dig(:foo, :jazz, :blues)
      end
      expect_raises TypeCastError, /cast from Bool to Hash\(.*?\) failed/ do
        hash.dig(:oof, :foo)
      end
    end

    it "extracts the nested value" do
      hash.dig(:foo).should eq({:jazz => "60s"})
      hash.dig(:foo, :jazz).should eq("60s")
    end
    it "extracts the nested nil value" do
      hash.dig(:zilch).should be_nil
    end
  end
end
