require "json"

module Kontrol
  # FIXME: convert to rule-instances instead of closures so expression can be captured
  alias Rule = JSON::Any -> Bool

  class RuleException < Exception
    getter rule_name : String
    getter rule_type : String
    getter rule_constraint : String

    def initialize(@rule_name, @rule_type, @rule_constraint, cause)
      super("Rule #{rule_name} with type #{rule_type} (#{rule_constraint}) raised: #{cause.message}", cause)
    end
  end

  abstract class Validator
    abstract def call(json : JSON::Any) : Hash(String, Array(Symbol))
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
          else
            errors[name.to_s] = [:required]
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

  class ObjectConverter(T)
    getter convert : JSON::Any -> T

    def initialize(@convert : JSON::Any -> T)
    end

    def call(json : JSON::Any) : T
      convert.call(json)
    end
  end

  macro object(**properties)
    {
      Kontrol::ObjectValidator.new(
        Hash(Symbol, Kontrol::Rule).new,
        Kontrol.convert_property_constraints_to_closures({{**properties}}).to_h
      ),
      Kontrol::ObjectConverter.new(
        Kontrol.convert_property_types_to_typecasts({{**properties}})
      )
    }
  end

  macro object(validations, **properties)
    {
      Kontrol::ObjectValidator.new(
        Kontrol.convert_constraints_to_untyped_closures({{**validations}}),
        Kontrol.convert_property_constraints_to_closures({{**properties}}).to_h
      ),
      Kontrol::ObjectConverter.new(
        Kontrol.convert_property_types_to_typecasts({{**properties}})
      )
    }
  end

  macro convert_property_types_to_typecasts(**properties)
    ->(json : JSON::Any) {
      {
        {% for name, definition in properties %}
          {% if definition.is_a?(Call) %}
            {{name}}: (Kontrol.{{definition}})[1].call(json[{{name.stringify}}]),
          {% elsif definition.is_a?(NamedTupleLiteral) %}
            {{name}}: json[{{name.stringify}}].raw.as({{definition[:type]}}),
          {% else %}
            {{name}}: json[{{name.stringify}}].raw.as({{definition}}),
          {% end %}
        {% end %}
      }
    }
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
          {{prop}}: (Kontrol.{{constraints}})[0].as(Hash(Symbol, Kontrol::Rule) | Kontrol::Validator),
        {% end %}
      {% end %}
    }.to_h
  end

  macro convert_constraints_to_untyped_closures(**constraints)
    {
      {% for name, constraint in constraints %}
        {{name}}: Kontrol.define_untyped_closure({{name.stringify}}, {{constraint}}),
      {% end %}
    }.to_h
  end

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
            Kontrol.define_typed_closure({{name.stringify}}, {{t}}, {{constraint}})
          ),
        {% end %}
      {% end %}
    }.to_h.as(Hash(Symbol, Kontrol::Rule) | Kontrol::Validator)
  end

  macro define_typed_closure(name, type, constraint)
    ->(v : JSON::Any) {
      v = v.raw.as({{type}})
      begin
        {{constraint}}
      rescue %e
        %constraint = <<-EX_MSG
          '{{constraint}}'
        EX_MSG

        raise RuleException.new({{name}}, "{{type}}", %constraint.strip, %e)
      end
    }.as(Kontrol::Rule)
  end

  macro define_untyped_closure(name, constraint)
    ->(v : JSON::Any) {
      begin
        {{constraint}}
      rescue %e
        %constraint = <<-EX_MSG
          '{{constraint}}'
        EX_MSG

        raise RuleException.new({{name}}, "JSON::Any", %constraint.strip, %e)
      end
    }.as(Kontrol::Rule)
  end
end
