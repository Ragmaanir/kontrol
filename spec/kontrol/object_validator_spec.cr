require "../spec_helper"

describe Kontrol::ObjectValidator do
  test "validates object" do
    v = ObjectValidator.new(
      {
        has_one_key: ObjectRule.new { |object| object.keys.size == 1 },
      },
      name: StringValidator.new,
      count: IntValidator.new
    )

    errors = v.call(json)

    assert errors.size == 3
    assert errors.map(&.name) == [:has_one_key, :missing, :missing]

    errors = v.call(json(name: 0))
    assert errors.size == 2
    assert errors.map(&.name) == [:type, :missing]

    errors = v.call(json(name: "test", count: 0))
    assert errors.map(&.name) == [:has_one_key]
  end

  test "complicated" do
    v = ObjectValidator.new(
      {
        has_name: ObjectRule.new { |object| object["name"]? != nil },
      },
      id: IntValidator.new(
        min: IntRule.new { |i| i > 0 },
      ),
      name: StringValidator.new(
        min_length: StringRule.new { |s| s.size > 2 },
      ),
    )

    errors = v.call(json(id: "aaa"))

    assert errors.size == 3
    assert errors.map(&.name) == [:has_name, :type, :missing]

    errors = v.call(json(id: 1, name: "x"))

    assert errors.size == 1
    assert errors.map(&.name) == [:min_length]

    errors = v.call(json(id: 1, name: "longenough"))

    assert errors.empty?
  end
end
