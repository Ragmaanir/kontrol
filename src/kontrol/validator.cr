require "json"

module Kontrol
  class Validator
    macro define(&block)
      v = Kontrol::ValidatorBuilder.new
      v.build {{block}}
      v.result
    end

    getter rules : Hash(Array(Symbol), Array(AbstractRule))

    def initialize(@rules)
    end

    def call(json : JSON::Any) : Array(Violation)
      violations = [] of Violation

      rules.each do |path, nested_rules|
        nested_rules.each do |rule|
          key = path.join(".")
          value = dig(key, json)

          if !rule.call(value)
            violations << Violation.new(key, rule, [] of String)
          end
        end
      end

      violations
    end

    private def dig(key : String, json : JSON::Any)
      node = json
      key.split(".").each do |k|
        node = node[k]?
        return unless node
      end

      node.raw
    end
  end
end
