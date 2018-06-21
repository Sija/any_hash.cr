require "json"

class AnyHash
  define_new klass: :JSON,
    key: Symbol | String,
    value: Nil | Number::Primitive | Bool | Symbol | String | Time | ::JSON::Any
end

require "./json/*"
