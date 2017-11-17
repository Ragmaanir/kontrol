# kontrol [![Build Status](https://travis-ci.org/Ragmaanir/kontrol.svg?branch=master)](https://travis-ci.org/Ragmaanir/kontrol)[![Dependency Status](https://shards.rocks/badge/github/ragmaanir/kontrol/status.svg)](https://shards.rocks/github/ragmaanir/kontrol)

### Version: 0.1.0

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
res = Kontrol.object(
  name: String,
  percentage: {type: Int64, min: v > 0, max: v <= 100}
)

# invalid since percentage violates :min constraint
assert res.call(json(
  name: "test",
  percentage: -1
)) == {"percentage" => [:min]}

# invalid since name violates :type-constraint and :min is violated
assert res.call(json(
  name: 2,
  percentage: -1
)) == {"name" => [:type], "percentage" => [:min]}

# invalid since the required attributes are missing or nil
assert res.call(json(
  name: nil
)) == {"name" => [:required], "percentage" => [:required]}

# valid
assert res.call(json(
  name: "test",
  percentage: 45
)).empty?

```

## TODOs

- [ ] Support arrays
- [ ] Support/test required/optional attributes
- [ ] Consistent handling of unspecified attributes (reject? ignore? errors?)
- [ ] Cleanup/simplify macros
- [ ] Use rule-class instances instead of closures?


## Contributing

1. Fork it ( https://github.com/[your-github-name]/kontrol/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [ragmaanir](https://github.com/ragmaanir) - creator, maintainer
