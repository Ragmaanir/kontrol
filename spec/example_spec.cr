require "./spec_helper"

describe Kontrol::Examples do
  test "tutorial" do
    {{`cat ./spec/examples/tutorial.cr`}}
  end

  test "simple" do
    {{`cat ./spec/examples/simple.cr`}}
  end

  test "advanced" do
    {{`cat ./spec/examples/advanced.cr`}}
  end
end
