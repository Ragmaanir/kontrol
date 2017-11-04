require "../spec_helper"

describe Kontrol::StringValidator do
  test "validates string" do
    v = object_validator(
      name: StringValidator.new(
        min: StringRule.new { |s| s.size >= 4 },
        max: StringRule.new { |s| s.size <= 6 },
      )
    )

    # not present
    errors = v.call(json)

    assert errors.size == 1
    assert errors.map(&.name) == [:missing]

    # wrong type
    errors = v.call(json(name: 1))

    assert errors.size == 1
    assert errors.map(&.name) == [:type]

    # value too small
    errors = v.call(json(name: "aaa"))

    assert errors.size == 1
    assert errors.map(&.name) == [:min]

    # value too big
    errors = v.call(json(name: "aaaaaaa"))

    assert errors.size == 1
    assert errors.map(&.name) == [:max]

    # success
    errors = v.call(json(name: "aaaaa"))

    assert errors.empty?
  end
end
