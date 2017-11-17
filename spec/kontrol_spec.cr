require "./spec_helper"

describe Kontrol do
  test "convert_sugared_constraints_to_closures"

  test "convert_constraints_to_untyped_closures" do
    val = convert_constraints_to_untyped_closures(min: v.as_i > 0)

    min = val[:min].as(Rule)
    assert min.call(JSON::Any.new(3.to_i64))
    assert !min.call(JSON::Any.new(-3.to_i64))
    assert_raises(RuleException) { !min.call(JSON::Any.new("String")) }
  end

  test "convert_property_constraints_to_closures" do
    res = val = convert_property_constraints_to_closures(
      name: String,
      count: {type: Int64, min: v > 0}
    )

    assert res.keys == [:name, :count]

    assert res[:name].keys == [:type]
    assert res[:count].keys == [:type, :min]

    type_rule = res[:name][:type].as(Rule)
    assert type_rule.call(JSON::Any.new("string"))
    assert !type_rule.call(JSON::Any.new(3.to_i64))

    min_rule = res[:count][:min].as(Rule)
    assert min_rule.call(JSON::Any.new(3.to_i64))
    assert !min_rule.call(JSON::Any.new(0.to_i64))
    assert_raises(TypeCastError) { min_rule.call(JSON::Any.new("string")) }
  end

  test "object without root validations" do
    res = object(
      name: String,
      count: {type: Int64, min: v > 0}
    )

    assert res.call(json(name: "test", count: 7)).empty?
    assert res.call(json(name: "test", count: -1)) == {"count" => [:min]}
    assert res.call(json(name: 2, count: -1)) == {"name" => [:type], "count" => [:min]}
    assert res.call(json(name: nil, count: nil)) == {"name" => [:required], "count" => [:required]}
  end

  test "object with root validations" do
    res = object(
      {
        name_length: v["name"].as_s.size == v["name_length"].as_i,
      },
      name: String,
      name_length: {type: Int64, min: v > 0}
    )

    assert res.call(json(name: "test")) == {"name_length" => [:required]}
    assert res.call(json(name: "test", name_length: 3)) == {"@" => [:name_length]}
    assert res.call(json(name: "test", name_length: 4)).empty?
  end

  test "nested objects" do
    res = object(
      name: String,
      data: object(
        key: String,
        value: Int64
      )
    )

    assert res.call(json(name: "test")) == {"data" => [:required]}

    assert res.call(json(data: {key: 1, value: "v"})) == {
      "name"       => [:required],
      "data.key"   => [:type],
      "data.value" => [:type],
    }

    assert res.call(json(name: 2, data: nil)) == {
      "name" => [:type],
      "data" => [:required],
    }

    assert res.call(json(name: "n", data: {key: "k", value: 123})).empty?
  end

  test "nested objects with root validations" do
    res = object(
      data: object(
        {
          length: v["name"].as_s.size == v["name_length"].as_i,
        },
        name: String,
        name_length: Int64
      )
    )

    assert res.call(json()) == {"data" => [:required]}

    assert res.call(json(data: {name: 1})) == {
      "data.name"        => [:type],
      "data.name_length" => [:required],
    }

    assert res.call(json(data: {name: "test", name_length: 3})) == {
      "data.@" => [:length],
    }

    assert res.call(json(data: {name: "test", name_length: 4})).empty?
  end
end
