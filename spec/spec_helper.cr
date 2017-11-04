require "microtest"
require "../src/kontrol"

include Microtest::DSL

class Microtest::Test
  include Kontrol

  def json(**h)
    JSON.parse(h.to_json)
  end

  def object_validator(**rules)
    ObjectValidator.new(
      {} of Symbol => ObjectRule,
      **rules
    )
  end
end

Microtest.run!
