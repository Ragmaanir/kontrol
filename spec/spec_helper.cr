require "microtest"
require "../src/kontrol"

include Microtest::DSL

class Microtest::Test
  include Kontrol

  def json(**h)
    JSON.parse(h.to_json)
  end
end

Microtest.run!([
  Microtest::DescriptionReporter.new,
  Microtest::ErrorListReporter.new,
  Microtest::SlowTestsReporter.new,
  Microtest::SummaryReporter.new,
] of Microtest::Reporter)
