# any_hash.cr [![CI](https://github.com/Sija/any_hash.cr/actions/workflows/ci.yml/badge.svg)](https://github.com/Sija/any_hash.cr/actions/workflows/ci.yml)

**AnyHash** is a library created to help with traversing and manipulation of
nested `Hash` structures.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  any_hash:
    github: sija/any_hash.cr
```

## Usage

```crystal
require "any_hash"
```

### Using `AnyHash::JSON`

`AnyHash::JSON` is ready-to-use JSON friendly version of `Hash`.

It takes care of casting immutable types to their mutable equivalents:
- `Tuple`      → `Array`
- `NamedTuple` → `Hash`

#### Traversing

```crystal
# possibly coming from `**options` argument, could be a `Hash` too
options = {
  status:  :published,
  tags:    {"crystal", "ruby", "sweet"},
  context: {
    user: {
      id: 123,
    }
  }
}

# convert any Hash or NamedTuple to `AnyHash::JSON` via `Object#to_any_json`
options = options.to_any_json

# return underlying `Hash`
options.to_h # => {:status => :published, :tags => ["crystal", "ruby", "sweet"], :context => {:user => {:id => 123}}}

# access direct descendant value
options[:status] # => :published

options[:status].class    # => Symbol
typeof(options[:status])  # => (Array(AnyHash::JSONTypes::Value) | Bool | Float32 | Float64 | Hash(String | Symbol, AnyHash::JSONTypes::Value) | Int16 | Int32 | Int64 | Int8 | Set(AnyHash::JSONTypes::Value) | String | Symbol | Time | UInt16 | UInt32 | UInt64 | UInt8 | Nil)

# access nested structures with key path
options[:context, :user, :id] # => 123

# `#[]` is an alias for `#dig`, same for `#[]?` -> `#dig?`
options[:context, :system, :os]?     # => nil
options.dig?(:context, :system, :os) # => nil
```

#### Manipulation

```crystal
# `#[]=` works with single keys and key paths
options[:featured] = true
options[:context, :user, :role] = :editor

defaults = {
  difficulty: :easy,
  status:     :draft,
  featured:   false,
  tags:       [] of String,
  context:    {} of Symbol => String
}

# merge defaults in-place
options.reverse_merge!(defaults)

# or return a copy with applied changes
settings = options.reverse_merge(defaults)

# merge nested structures
options.merge! context: {user: {email: "foo@bar.org"}}

# or single values
options.merge! id: 420
```

### Defining your own class

```crystal
AnyHash.define_new klass: :DegreesOfLogic,
  key: Symbol | String,
  value: Bool

DegreesOfLogic.new({ there: { are: { many: { truths: true, or: false }}}})
```

## Development

Run specs with:

```
crystal spec
```

## Contributing

1. Fork it ( https://github.com/sija/any_hash.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [sija](https://github.com/sija) Sijawusz Pur Rahnama - creator, maintainer
