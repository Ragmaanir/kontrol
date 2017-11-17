require "./spec_helper"

describe Kontrol::Examples do
  test "tutorial" do
    {{`cat ./spec/examples/tutorial.cr`}}
  end

  test "simple example" do
    {{`cat ./spec/examples/simple.cr`}}
  end

  test "nested objects" do
    {{`cat ./spec/examples/advanced.cr`}}
  end
end
