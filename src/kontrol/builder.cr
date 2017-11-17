module Kontrol
  class Builder
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
      Kontrol::Builder::ObjectValidator.new(
        Hash(Symbol, Kontrol::Builder::Rule).new,
        Kontrol::Builder.convert_property_constraints_to_closures({{**properties}}).to_h
      )
    end

    macro object(validations, **properties)
      Kontrol::Builder::ObjectValidator.new(
        Kontrol::Builder.convert_constraints_to_closures(Hash(String, JSON::Type), {{**validations}}),
        Kontrol::Builder.convert_property_constraints_to_closures({{**properties}}).to_h
      )
    end

    macro convert_property_constraints_to_closures(**properties)
      {
        {% for prop, constraints in properties %}
          {% if constraints.is_a?(NamedTupleLiteral) %}
            {{prop}}: Kontrol::Builder.convert_sugared_constraints_to_closures({{constraints}}),
          {% elsif constraints.is_a?(Path) && constraints.resolve? %}
            {{prop}}: Kontrol::Builder.convert_sugared_constraints_to_closures({type: {{constraints}}}),
          {% else %}
            # to invoke Kontrol::Builder.object
            {{prop}}: (Kontrol::Builder.{{constraints}}).as(Hash(Symbol, Kontrol::Builder::Rule) | Kontrol::Builder::Validator),
          {% end %}
        {% end %}
      }.to_h
    end

    # FIXME: convert to rule-instances instead of closures so expression can be captured
    macro convert_constraints_to_closures(type, **constraints)
      {
        {% for name, constraint in constraints %}
          {{name}}: Kontrol::Builder.define_typed_closure({{type}}, {{constraint}}),
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
              Kontrol::Builder.define_typed_closure({{t}}, {{constraint}})
            ),
          {% end %}
        {% end %}
      }.to_h.as(Hash(Symbol, Kontrol::Builder::Rule) | Kontrol::Builder::Validator)
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
      }.as(Kontrol::Builder::Rule)
    end
  end

  # class ValidatorBuilder
  #   @path : Array(Symbol)
  #   @validators : Array(Hash(Symbol, Array(Validator)))

  #   # getter rules : Hash(Array(Symbol), Array(AbstractRule))

  #   def initialize
  #     @path = [] of Symbol
  #     # @rules = {} of Array(Symbol) => Array(AbstractRule)
  #     @validators = [] of Hash(Symbol, Array(Validator))
  #   end

  #   def build
  #     with self yield
  #   end

  #   macro object(**rules, &block)
  #     %rules = {
  #       {% for name, rule in rules %}
  #         {{name.id}}: ObjectRule.new do |v|
  #           {{rule}}
  #         end,
  #       {% end %}
  #     } of Symbol => ObjectRule

  #     %v = ValidatorBuilder.new
  #     %validators = %v.build {{block}}

  #     if %validators
  #       Kontrol::ObjectValidator.new(%rules, %validators)
  #     else
  #       Kontrol::ObjectValidator.new(%rules, **NamedTuple.new)
  #     end
  #   end

  #   macro array(name, type, **validations)
  #     # create_rules(ArrayRule, {{name}}, {{type}}, type_check: v.all?(&.is_a?({{type}})))
  #     # create_rules(ArrayRule, {{name}}, {{type}}, {{**validations}})
  #     %rules = create_rules(ArrayRule, {{name}}, {{type}}, type_check: v.all?(&.is_a?({{type}}), {{**validations}})
  #     Kontrol::ArrayValidator.new(%rules)
  #   end

  #   macro array(name, **validations, &block)
  #     create_rules(ArrayRule, {{name}}, JSON::Type, {{**validations}})

  #     nested({{name}}) {{block}}
  #   end

  #   TYPE_MAP = {
  #     string: String,
  #     int:    Int64,
  #     float:  Float64,
  #     bool:   Bool,
  #   }

  #   {% for n, cls in TYPE_MAP %}
  #     macro {{n.id}}(name, **rules)
  #       %rules = {
  #         \{% for k, rule in rules %}
  #           \{{k}}: \{{rule}},
  #         \{% end %}
  #       } of Symbol => {{n.stringify.capitalize.id}}Rule

  #       {{n.stringify.capitalize.id}}Validator.new(%rules)
  #     end
  #   {% end %}

  #   macro primitive(name, type, **validations)
  #     #create_primitive_rules({{name}}, {{type}}, type_check: v.is_a?({{type}}))
  #     %rules = create_primitive_rules({{type}}, type_check: v.is_a?({{type}}), {{**validations}})
  #     _push_validator(Kontrol::{{type}}Validator.new({{name}}, %rules))
  #   end

  #   macro create_primitive_rules(type, **validations)
  #     %rules = {} of Symbol => Kontrol::AbstractRule

  #     {% for n, c in validations %}

  #       {% if type.class_name != "Path" %}
  #           {% raise "Invalid type class #{type.class_name}, expected Path" %}
  #       {% end %}

  #       {% if !%w{Int64 Float64 String Bool Nil}.includes?(type.names.first.stringify) %}
  #           {% raise "Invalid type #{type.names.first}" %}
  #       {% end %}

  #       %cond = ->(v : {{type}}){
  #         {{c}}
  #       }

  #       %rules[:{{n}}] = Kontrol::{{type}}Rule.new(:{{n}}, %cond)

  #     {% end %}

  #     %rules
  #   end

  #   macro create_array_rules(rule, name, type, **validations)
  #     %rules = {} of Symbol => Kontrol::AbstractRule

  #     {% for n, c in validations %}

  #       {% if type.class_name != "Path" %}
  #           {% raise "Invalid type class #{type.class_name}, expected Path" %}
  #       {% end %}

  #       {% if !%w{Int64 Float64 String Bool Nil}.includes?(type.names.first.stringify) %}
  #           {% raise "Invalid type #{type.names.first}" %}
  #       {% end %}

  #       %cond = ->(v : Array({{type}})){
  #         {{c}}
  #       }

  #       %rules[{{name}}] = Kontrol::{{rule}}{{type}}.new(:{{n}}, %cond)

  #     {% end %}

  #     %rules
  #   end

  #   macro nested(name, &block)
  #     _push {{name}}
  #     {% if block.class_name != "Nop" %}
  #       {{block.body}}
  #     {% end %}
  #     _pop
  #   end

  #   def _push_validator(validator : Validator)
  #     @validators.last << validator
  #   end

  #   def _push(name)
  #     @path << name
  #     @validators.push([] of Validator)
  #   end

  #   def _pop
  #     @validators.pop
  #     @path.pop
  #   end

  #   # def _add(name, rule)
  #   #   full_path = @path + [name]
  #   #   @rules[full_path] ||= [] of AbstractRule
  #   #   @rules[full_path] << rule
  #   # end

  #   def result
  #     ObjectValidator.new(rules)
  #   end
  # end
end
