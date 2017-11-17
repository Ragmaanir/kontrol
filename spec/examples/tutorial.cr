# To define a validation you can use the `Kontrol.object` macro.
# Validations can be defined by expressions:

Kontrol.object(
  name: {type: String, length: v.size > 4},
)

# This will return `{"name" => [:length]}` if the constraint `length` is violated.
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
