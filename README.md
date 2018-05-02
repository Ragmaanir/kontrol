# kontrol [![Build Status](https://travis-ci.org/Ragmaanir/kontrol.svg?branch=master)](https://travis-ci.org/Ragmaanir/kontrol)[![Dependency Status](https://shards.rocks/badge/github/ragmaanir/kontrol/status.svg)](https://shards.rocks/github/ragmaanir/kontrol)

### Version: 0.2.2

Kontrol is a DSL to define validations for JSON data.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  kontrol:
    github: ragmaanir/kontrol
```

## Usage

```crystal
require "kontrol"
```

```crystal
# To define a validation you can use the `Kontrol.object` macro.
# Validations can be defined by expressions:

val, _ = Kontrol.object(
  name: {type: String, length: v.size > 4},
)

# When the constraint `length` is violated it returns:

j = json(name: "a")
assert val.call(j) == {"name" => [:length]}

# The value of the property `name` can be accessed via `v` in the validation expression.

# For the type validation there are two shortcuts since they are so common:

# Shortcut 1
Kontrol.object(
  name: {type: String},
)

# Shortcut 2
Kontrol.object(
  name: String,
)

# You always have to specify the type (might change).

# You can also define root-level validations for an object:

val, _ = Kontrol.object(
  {length: v["name"].as_s.size == v["name_length"].as_i},
  name: String,
  name_length: Int64
)

# The `length` validation checks whether the length of the name string matches the name_length.
# The root-level validations are only executed when all properties are valid to prevent
# them raising exceptions caused by invalid data. A root level validation error
# is stored under the key "@", because the object might not have a name. So in this case:
j = json(
  name: "test",
  name_length: 3
)

assert val.call(j) == {
  "@" => [:length],
}

```

Simple example:

```crystal
# First object is the validator, second is the converter that can be used
# to convert the JSON to nested named tuples.
val, con = Kontrol.object(
  name: String,
  percentage: {type: Int64, min: v > 0, max: v <= 100}
)

# invalid since percentage violates :min constraint
assert val.call(json(
  name: "test",
  percentage: -1
)) == {"percentage" => [:min]}

# invalid since name violates :type-constraint and :min is violated
assert val.call(json(
  name: 2,
  percentage: -1
)) == {"name" => [:type], "percentage" => [:min]}

# invalid since the required attributes are missing or nil
assert val.call(json(
  name: nil
)) == {"name" => [:required], "percentage" => [:required]}

# valid
assert val.call(json(
  name: "test",
  percentage: 45
)).empty?

# convert input to nested named tuples
assert con.call(json(
  name: "test",
  percentage: 45
)) == {name: "test", percentage: 45}

```

Advanced example (nested objects and root-level-validations):

```crystal
res, _ = object(
  {
    my_book: v["author"].as_s == v["book"]["author"].as_s,
  },
  author: String,
  book: object(
    author: String
  )
)

assert res.call(json(
  author: "Bob"
)) == {"book" => [:required]}

assert res.call(json(
  author: "Bob",
  book: {
    author: 1337,
  }
)) == {"book.author" => [:type]}

assert res.call(json(
  author: "Bob",
  book: {
    author: "Bobby",
  }
)) == {"@" => [:my_book]}

assert res.call(json(
  author: "Bob",
  book: {
    author: "Bob",
  }
)).empty?

```

## TODOs

- [ ] Support arrays
- [ ] Support/test required/optional attributes
- [ ] Consistent handling of unspecified attributes (reject? ignore? errors?)
- [ ] Cleanup/simplify macros
- [ ] Use rule-class instances instead of closures?


## Contributing

1. Fork it ( https://github.com/ragmaanir/kontrol/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [ragmaanir](https://github.com/ragmaanir) - creator, maintainer
