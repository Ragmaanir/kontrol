require "./spec_helper"

describe Kontrol::Examples do
  def json(**hash)
    JSON.parse(hash.to_json)
  end

  test "simple example" do
    {{`cat ./spec/examples/simple_example.cr`}}
  end
end
