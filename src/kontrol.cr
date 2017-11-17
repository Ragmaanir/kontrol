require "json"

require "./kontrol/*"

module Kontrol
  alias Rule = JSON::Any -> Bool

  class Result
    alias Errors = Hash(String, Errors | Array(Symbol))
    getter errors : Errors

    def initialize(@errors)
    end
  end

  abstract class Validator
    abstract def call(json : JSON::Any) : Errors
  end

  class ObjectValidator < Validator
    getter validations : Hash(Symbol, Rule)
    getter properties : Hash(Symbol, Hash(Symbol, Rule) | Validator)

    def initialize(@validations, @properties)
    end

    def keys
      properties.keys
    end

    def [](name : Symbol)
      properties[name]
    end

    def call(json : JSON::Any) : Hash(String, Array(Symbol))
      errors = validate_properties(json)

      if errors.empty?
        errors = errors.merge(validate_object_constraints(json))
      end

      errors
    end

    private def validate_object_constraints(json : JSON::Any) : Hash(String, Array(Symbol))
      errors = {} of String => Array(Symbol)

      failed = validations.reject do |name, constraint|
        constraint.call(json)
      end.map(&.[0])

      errors["@"] = failed unless failed.empty?

      errors
    end

    private def validate_properties(json : JSON::Any) : Hash(String, Array(Symbol))
      errors = {} of String => Array(Symbol)

      properties.each do |name, constraints|
        case c = constraints
        when Validator
          if nested = json[name.to_s]?
            validator_errors = c.call(nested)
            validator_errors.each do |nested_name, nested_err|
              errors["#{name}.#{nested_name}"] = nested_err
            end
          end
        when Hash(Symbol, Rule)
          prop_errors = validate_property_constraints(name, c, json[name.to_s]?)

          if !prop_errors.empty?
            errors[name.to_s] = prop_errors
          end
        else raise "Invalid type: #{c.class}"
        end
      end

      errors
    end

    private def validate_property_constraints(prop_name : Symbol, constraints : Hash(Symbol, Rule), value : JSON::Any?) : Array(Symbol)
      if value
        if t = constraints[:type]
          return [:type] unless t.call(value)
        end

        errors = [] of Symbol

        constraints.reject(:type).each do |name, constraint|
          errors << name unless constraint.call(value)
        end

        return errors
      elsif constraints[:optional]?
        return [] of Symbol
      else
        # FIXME: implement required
        return [:required]
      end
    end
  end

  macro object(**properties)
      Kontrol::ObjectValidator.new(
        Hash(Symbol, Kontrol::Rule).new,
        Kontrol.convert_property_constraints_to_closures({{**properties}}).to_h
      )
    end

  macro object(validations, **properties)
      Kontrol::ObjectValidator.new(
        Kontrol.convert_constraints_to_closures(Hash(String, JSON::Type), {{**validations}}),
        Kontrol.convert_property_constraints_to_closures({{**properties}}).to_h
      )
    end

  macro convert_property_constraints_to_closures(**properties)
      {
        {% for prop, constraints in properties %}
          {% if constraints.is_a?(NamedTupleLiteral) %}
            {{prop}}: Kontrol.convert_sugared_constraints_to_closures({{constraints}}),
          {% elsif constraints.is_a?(Path) && constraints.resolve? %}
            {{prop}}: Kontrol.convert_sugared_constraints_to_closures({type: {{constraints}}}),
          {% else %}
            # to invoke Kontrol.object
            {{prop}}: (Kontrol.{{constraints}}).as(Hash(Symbol, Kontrol::Rule) | Kontrol::Validator),
          {% end %}
        {% end %}
      }.to_h
    end

  # FIXME: convert to rule-instances instead of closures so expression can be captured
  macro convert_constraints_to_closures(type, **constraints)
      {
        {% for name, constraint in constraints %}
          {{name}}: Kontrol.define_typed_closure({{type}}, {{constraint}}),
        {% end %}
      }.to_h
    end

  # FIXME: convert to rule-instances instead of closures so expression can be captured
  macro convert_sugared_constraints_to_closures(constraints)
      {% t = constraints[:type] %}

      {% if !t %}
        {% raise "convert_sugared_constraints_to_closures: type is missing in #{constraints}" %}
      {% end %}

      {
        type: (
          ->(v : JSON::Any) { v.raw.is_a?({{t}})}
        ),
        {% for name, constraint in constraints %}
          {% if name != :type %}
            {{name}}: (
              Kontrol.define_typed_closure({{t}}, {{constraint}})
            ),
          {% end %}
        {% end %}
      }.to_h.as(Hash(Symbol, Kontrol::Rule) | Kontrol::Validator)
    end

  macro define_typed_closure(type, constraint)
      ->(v : JSON::Any) {
        v = v.raw.as({{type}})
        begin
          {{constraint}}
        rescue e
          raise <<-EXC_MSG
            Validation '{{constraint}}' raise (#{e})
          EXC_MSG
        end
      }.as(Kontrol::Rule)
    end
end
