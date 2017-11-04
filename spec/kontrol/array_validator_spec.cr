require "../spec_helper"

describe Kontrol::ArrayValidator do
  test "validates array" do
    v = ObjectValidator.new(
      {} of Symbol => ObjectRule,
      items: IntArrayValidator.new
    )

    errors = v.call(json)

    assert errors.size == 1
    assert errors.map(&.name) == [:missing]

    errors = v.call(json(items: [] of Int32))
    assert errors.empty?

    errors = v.call(json(items: ["string"]))
    assert errors.size == 1
    assert errors[0].path == Path.new(".items[0]")
    assert errors[0].name == :type

    errors = v.call(json(items: [1, "string"]))
    assert errors.size == 1
    assert errors[0].path == Path.new(".items[1]")
    assert errors[0].name == :type

    errors = v.call(json(items: [1]))
    assert errors.empty?
  end
end
