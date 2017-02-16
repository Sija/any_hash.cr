class Object
  # TODO: moar!
  macro any_json_property(*attr_names)
    {% for attr_name in attr_names %}
      property {{attr_name.id}} : AnyHash::JSON { AnyHash::JSON.new }

      def {{attr_name.id}}=(hash : Hash | NamedTuple?)
        {{attr_name.id}}.replace(hash)
      end
    {% end %}
  end
end

class Hash
  # Returns `self` as `AnyHash::JSON`.
  def to_any_json
    AnyHash::JSON.new(self)
  end
end

struct NamedTuple
  # Returns `self` as `AnyHash::JSON`.
  def to_any_json
    AnyHash::JSON.new(self)
  end
end
