require "../spec_helper"

describe Kontrol::FloatValidator do
  test "validates float" do
    v = object_validator(
      ratio: FloatValidator.new(
        min: FloatRule.new { |r| r >= 0 },
        max: FloatRule.new { |r| r <= 1 },
      )
    )

    # not present
    errors = v.call(json)

    assert errors.size == 1
    assert errors.map(&.name) == [:missing]

    # wrong type
    errors = v.call(json(ratio: "aaa"))

    assert errors.size == 1
    assert errors.map(&.name) == [:type]

    # value too small
    errors = v.call(json(ratio: -0.2))

    assert errors.size == 1
    assert errors.map(&.name) == [:min]

    # value too big
    errors = v.call(json(ratio: 1.2))

    assert errors.size == 1
    assert errors.map(&.name) == [:max]

    # success
    errors = v.call(json(ratio: 0.5))

    assert errors.empty?
  end
end
