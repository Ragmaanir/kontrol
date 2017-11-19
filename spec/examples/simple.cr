# First object is the validator, second is the converter that can be used
# to convert the JSON to nested named tuples.
val, con = Kontrol.object(
  name: String,
  percentage: {type: Int64, min: v > 0, max: v <= 100}
)

# invalid since percentage violates :min constraint
assert val.call(json(
  name: "test",
  percentage: -1
)) == {"percentage" => [:min]}

# invalid since name violates :type-constraint and :min is violated
assert val.call(json(
  name: 2,
  percentage: -1
)) == {"name" => [:type], "percentage" => [:min]}

# invalid since the required attributes are missing or nil
assert val.call(json(
  name: nil
)) == {"name" => [:required], "percentage" => [:required]}

# valid
assert val.call(json(
  name: "test",
  percentage: 45
)).empty?

# convert input to nested named tuples
assert con.call(json(
  name: "test",
  percentage: 45
)) == {name: "test", percentage: 45}
