require "../spec_helper"

describe Kontrol::IntValidator do
  test "validates int" do
    v = object_validator(
      id: IntValidator.new(
        min: IntRule.new { |i| i >= 0 },
        max: IntRule.new { |i| i <= 100 },
      )
    )

    # not present
    errors = v.call(json)

    assert errors.size == 1
    assert errors.map(&.name) == [:missing]

    # wrong type
    errors = v.call(json(id: "aaa"))

    assert errors.size == 1
    assert errors.map(&.name) == [:type]

    # value too small
    errors = v.call(json(id: -1))

    assert errors.size == 1
    assert errors.map(&.name) == [:min]

    # value too big
    errors = v.call(json(id: 101))

    assert errors.size == 1
    assert errors.map(&.name) == [:max]

    # success
    errors = v.call(json(id: 35))

    assert errors.empty?
  end
end
