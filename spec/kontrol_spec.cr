require "./spec_helper"

describe Kontrol do
  test "convert_constraints_to_closures" do
    val = convert_constraints_to_closures(Int64, min: v > 0)

    min = val[:min].as(Rule)
    assert min.call(JSON::Any.new(3.to_i64))
    assert !min.call(JSON::Any.new(-3.to_i64))
    assert_raises(TypeCastError) { !min.call(JSON::Any.new("String")) }
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

    assert res.call(json(name: "test", count: 7)) == {} of Symbol => Array(Symbol)
    assert res.call(json(name: "test", count: -1)) == {"count" => [:min]}.to_h
    assert res.call(json(name: 2, count: -1)) == {"name" => [:type], "count" => [:min]}.to_h
    assert res.call(json(name: nil, count: nil)) == {"name" => [:required], "count" => [:required]}.to_h
  end

  test "object with root validations" do
    res = object(
      {
        name_length: v["name"].as(String).size == v["name_length"].as(Int64),
      },
      name: String,
      name_length: {type: Int64, min: v > 0}
    )

    assert res.call(json(name: "test")) == {"name_length" => [:required]}.to_h
    assert res.call(json(name: "test", name_length: 3)) == {"@" => [:name_length]}
    assert res.call(json(name: "test", name_length: 4)) == {} of String => Array(Symbol)
  end

  test "nested objects" do
    res = object(
      name: String,
      data: object(
        key: String,
        value: Int64
      )
    )

    assert res.call(json(name: "test")) == {} of String => JSON::Type

    assert res.call(json(data: {key: 1, value: "v"})) == {
      "name"       => [:required],
      "data.key"   => [:type],
      "data.value" => [:type],
    }

    assert res.call(json(name: 2, data: nil)) == {
      "name" => [:type],
    }

    assert res.call(json(name: "n", data: {key: "k", value: 123})) == {} of String => JSON::Type
  end
end
