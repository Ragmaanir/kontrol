# To define a validation you can use the `Kontrol.object` macro.
# Validations can be defined by expressions:

k, _ = Kontrol.object(
  name: {type: String, length: v.size > 4},
)

# When the constraint `length` is violated it returns:

j = json(name: "a")
assert k.call(j) == {"name" => [:length]}

# The value of the property `name` can be accessed via `v` in the validation expression.

# For the type validation there are two shortcuts since they are so common:

# Shortcut 1
Kontrol.object(
  name: {type: String},
)

# Shortcut 2
Kontrol.object(
  name: String,
)

# You always have to specify the type (might change).

# You can also define root-level validations for an object:

k, _ = Kontrol.object(
  {length: v["name"].as_s.size == v["name_length"].as_i},
  name: String,
  name_length: Int64
)

# The `length` validation checks whether the length of the name string matches the name_length.
# The root-level validations are only executed when all properties are valid to prevent
# them raising exceptions caused by invalid data. A root level validation error
# is stored under the key "@", because the object might not have a name. So in this case:
j = json(
  name: "test",
  name_length: 3
)

assert k.call(j) == {
  "@" => [:length],
}
