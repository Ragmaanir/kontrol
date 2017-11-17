require "./spec_helper"

describe Kontrol::Examples do
  def json(**hash)
    JSON.parse(hash.to_json)
  end

  test "simple example" do
    {{`cat ./spec/examples/simple.cr`}}
  end

  test "nested objects" do
    {{`cat ./spec/examples/advanced.cr`}}
  end
end
