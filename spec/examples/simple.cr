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
