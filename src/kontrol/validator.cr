require "json"

require "./path"

module Kontrol
  abstract class Validator
    macro define(&block)
      v = Kontrol::ValidatorBuilder.new
      v.build {{block}}
      v.result
    end

    abstract def call(json : JSON::Any?, path : Path = Path.root) : Array(Violation)
  end

  PRIMITIVE_TYPES = {
    String: String,
    Int:    Int64,
    Float:  Float64,
    Bool:   Bool,
  }

  {% for short, type in PRIMITIVE_TYPES %}
    class {{short.id}}Validator < Validator
      getter rules : Hash(Symbol, {{short.id}}Rule)

      def initialize(**rules)
        @rules = {} of Symbol => {{short.id}}Rule
        rules.each do |k,v|
          @rules[k] = v
        end
      end

      def call(json : JSON::Any?, path : Path = Path.root) : Array(Violation)
        if !json
          return [Violation.new(:missing, path)]
        elsif !json.raw.is_a?({{type}})
          return [Violation.new(:type, path)]
        end

        value = json.raw.as({{type.id}})

        violations = [] of Violation

        rules.each do |name, rule|
          if !rule.call(value)
            violations << Violation.new(name, path)
          end
        end

        violations
      end
    end
  {% end %}

  class ObjectValidator < Validator
    getter rules : Hash(Symbol, ObjectRule)
    getter children : Hash(Symbol, Validator)

    def initialize(rules, **children)
      @rules = rules.to_h

      # Convert specific validator instances to superclass
      @children = {} of Symbol => Validator
      children.each do |k, v|
        @children[k] = v
      end
    end

    def call(json : JSON::Any?, path : Path = Path.root) : Array(Violation)
      if !json
        return [Violation.new(:missing, path)]
      elsif !json.as_h?
        return [Violation.new(:type, path)]
      end

      violations = [] of Violation

      rules.each do |name, rule|
        if !rule.call(json.as_h)
          violations << Violation.new(name, path)
        end
      end

      children.each do |child_name, child|
        violations += child.call(json[child_name.to_s]?, path.child(child_name.to_s))
      end

      violations
    end
  end

  {% for name, type in PRIMITIVE_TYPES %}
    class {{name}}ArrayValidator < Validator
      getter rules : Hash(Symbol, {{name}}ArrayRule)
      getter child : Validator

      def initialize(@child = {{name}}Validator.new, **rules)
        @rules = {} of Symbol => {{name}}ArrayRule
        rules.each do |k,v|
          @rules[k] = v
        end
      end

      def call(json : JSON::Any?, path : Path = Path.root) : Array(Violation)
        if !json
          return [Violation.new(:missing, path)]
        elsif !json.as_a?
          return [Violation.new(:type, path)]
        end

        violations = [] of Violation

        rules.each do |name, rule|
          if !rule.call(json.as_a)
            violations << Violation.new(name, path)
          end
        end

        json.as_a.each_with_index do |entry, i|
          violations += child.call(JSON::Any.new(entry), path.index(i))
        end

        violations
      end
    end
  {% end %}
end
