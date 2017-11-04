require "../spec_helper"

describe Kontrol::BoolValidator do
  test "validates bool" do
    v = object_validator(
      enabled: BoolValidator.new(
        expected: BoolRule.new { |e| e == true }
      )
    )

    # not present
    errors = v.call(json)

    assert errors.size == 1
    assert errors.map(&.name) == [:missing]

    # wrong type
    errors = v.call(json(enabled: "aaa"))

    assert errors.size == 1
    assert errors.map(&.name) == [:type]

    # value incorrect
    errors = v.call(json(enabled: false))

    assert errors.size == 1
    assert errors.map(&.name) == [:expected]

    # success
    errors = v.call(json(enabled: true))

    assert errors.empty?
  end
end
