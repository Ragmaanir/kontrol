require "./spec_helper"

describe Kontrol do
  EMPTY_ARRAY = [] of String

  def json(**h)
    JSON.parse(h.to_json)
  end

  pending "works" do
    val = Validator.define do
      required(:settings) do
        required(:max_items, Int64, min: v > 0)
      end
      required(:items, Array(JSON::Type), id_uniqueness: v.size > 0) do
        required(:name, String, min: v.size > 0, max: v.size <= 32)
        required(:id, String, length: (16..64).includes?(v.size))
      end
      # required(:items, Array(JSON::Type),
      #   id_uniqueness: v.map(&.as_h["name"]).uniq.size == v.size,
      #   #id_uniqueness: v.uniq?(&.name),
      #   max_items: v.size < root.settings.max_items,
      # ) do
      #   required(:name, String, min: v.size > 0, max: v.size <= 32)
      #   required(:id, String, length: included_in?(v.size, 16..64))
      # end
    end

    val = Validator.define do
      required(:name, String)
    end
  end

  test "empty validation" do
    val = Validator.define do
    end

    assert val.call(json(name: "test")) == [] of Violation
  end

  test "required" do
    val = Validator.define do
      required(:name, String)
    end

    assert val.call(json(name: "test")) == [] of Violation
    assert val.call(json(other: "test")).size == 1
  end

  test! "required Int64" do
    val = Validator.define do
      int(:count)
    end

    j = json(count: 1337)
    assert val.call(j).size == 0
    j = json(count: "test")
    assert val.call(j).size == 1
    j = json(other: "test")
    assert val.call(j).size == 1
  end

  test! "array of Int64" do
    val = Validator.define do
      array(:items, Int64, required: true)
    end

    j = json(items: EMPTY_ARRAY)
    assert val.call(j).size == 0
  end

  test "array of array of Int64" do
    val = Validator.define do
      array(:items, required: true) do
        array(:name, String)
      end
    end

    j = json(items: EMPTY_ARRAY)
    assert val.call(j).size == 0
  end
end
