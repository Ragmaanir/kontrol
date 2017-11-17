require "../spec_helper"

describe Kontrol::Builder do
  def json(**hash)
    JSON.parse(hash.to_json)
  end

  test "convert_constraints_to_closures" do
    val = Kontrol::Builder.convert_constraints_to_closures(Int64, min: v > 0)

    min = val[:min].as(Kontrol::Builder::Rule)
    assert min.call(JSON::Any.new(3.to_i64))
    assert !min.call(JSON::Any.new(-3.to_i64))
    assert_raises(TypeCastError) { !min.call(JSON::Any.new("String")) }
  end

  test "convert_property_constraints_to_closures" do
    res = val = Kontrol::Builder.convert_property_constraints_to_closures(
      name: String,
      count: {type: Int64, min: v > 0}
    )

    assert res.keys == [:name, :count]

    assert res[:name].keys == [:type]
    assert res[:count].keys == [:type, :min]

    type_rule = res[:name][:type].as(Kontrol::Builder::Rule)
    assert type_rule.call(JSON::Any.new("string"))
    assert !type_rule.call(JSON::Any.new(3.to_i64))

    min_rule = res[:count][:min].as(Kontrol::Builder::Rule)
    assert min_rule.call(JSON::Any.new(3.to_i64))
    assert !min_rule.call(JSON::Any.new(0.to_i64))
    assert_raises(TypeCastError) { min_rule.call(JSON::Any.new("string")) }
  end

  test "object without root validations" do
    res = Kontrol::Builder.object(
      name: String,
      count: {type: Int64, min: v > 0}
    )

    assert res.call(json(name: "test", count: 7)) == {} of Symbol => Array(Symbol)
    assert res.call(json(name: "test", count: -1)) == {"count" => [:min]}.to_h
    assert res.call(json(name: 2, count: -1)) == {"name" => [:type], "count" => [:min]}.to_h
    assert res.call(json(name: nil, count: nil)) == {"name" => [:required], "count" => [:required]}.to_h
  end

  test "object with root validations" do
    res = Kontrol::Builder.object(
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
    res = Kontrol::Builder.object(
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

# Validator.array(
#   Validator.object do
#   end
# )

# Validator.array(
#   Validator.array(Int32)
# )

# array(array(Int32))

# # A
# object(min_books: v.books.size > 0) do
#   array(:books,
#     object do
#       string(:name, size: v.size > 0)
#       int(:page, min: v > 0)
#       object(:author, required: true) do
#         string(:name, min: v.size > 0)
#       end
#     end
#   )
# end

# # B
# object(min_books: v.books.size > 0) do
#   field(:books, array(
#     object do
#       field(:name, String, size: v.size > 0)
#       field(:page, Int64, min: v > 0)
#       field(:author, required: true) do
#         field(:name, String, min: v.size > 0)
#       end
#     end
#   ))
# end

# # C <- XXX
# object(
#   {min_books: v.books.size > 0},
#   books: array(
#     object(
#       name: {type: String, size: v.size > 0},
#       page: {type: Int64, min: v > 0},
#       author: object(
#         {required: true},
#         name: {type: String, min: v.size > 0}
#       )
#     )
#   )
# )

# object(
#   percentage: {type: Int64, min: v > 0, max: v < 100},
#   author: object(
#     name: String
#   ),
#   books: array(Int32, min: v > 0),
#   lists: array(
#     array(String, min: v.size > 3)
#   )
# )
