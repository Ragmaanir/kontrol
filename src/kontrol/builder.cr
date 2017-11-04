module Kontrol
  class ValidatorBuilder
    @path : Array(Symbol)
    @validators : Array(Hash(Symbol, Array(Validator)))
    getter rules : Hash(Array(Symbol), Array(AbstractRule))

    def initialize
      @path = [] of Symbol
      @rules = {} of Array(Symbol) => Array(AbstractRule)
      @validators = [] of Hash(Symbol, Array(Validator))
    end

    def build
      with self yield
    end

    macro array(name, type, **validations)
      # create_rules(ArrayRule, {{name}}, {{type}}, type_check: v.all?(&.is_a?({{type}})))
      # create_rules(ArrayRule, {{name}}, {{type}}, {{**validations}})
      %rules = create_rules(ArrayRule, {{name}}, {{type}}, type_check: v.all?(&.is_a?({{type}}), {{**validations}})
      Kontrol::ArrayValidator.new(%rules)
    end

    macro array(name, **validations, &block)
      create_rules(ArrayRule, {{name}}, JSON::Type, {{**validations}})

      nested({{name}}) {{block}}
    end

    TYPE_MAP = {
      string: String,
      int:    Int64,
      float:  Float64,
      bool:   Bool,
    }

    {% for n, cls in TYPE_MAP %}
      macro {{n.id}}(name, **validations)
        primitive(\{{name}}, {{cls.id}}, \{{**validations}})
      end
    {% end %}

    macro primitive(name, type, **validations)
      #create_primitive_rules({{name}}, {{type}}, type_check: v.is_a?({{type}}))
      %rules = create_primitive_rules({{type}}, type_check: v.is_a?({{type}}), {{**validations}})
      _push_validator(Kontrol::PrimitiveValidator.new({{name}}, %rules))
    end

    macro create_primitive_rules(type, **validations)
      %rules = {} of Symbol => Kontrol::AbstractRule

      {% for n, c in validations %}

        {% if type.class_name != "Path" %}
            {% raise "Invalid type class #{type.class_name}, expected Path" %}
        {% end %}

        {% if !%w{Int64 Float64 String Bool Nil}.includes?(type.names.first.stringify) %}
            {% raise "Invalid type #{type.names.first}" %}
        {% end %}

        %cond = ->(v : {{type}}){
          {{c}}
        }

        %rules[:{{n}}] = Kontrol::PrimitiveRule{{type}}.new(:{{n}}, %cond)

      {% end %}

      %rules
    end

    macro create_array_rules(rule, name, type, **validations)
      %rules = {} of Symbol => Kontrol::AbstractRule

      {% for n, c in validations %}

        {% if type.class_name != "Path" %}
            {% raise "Invalid type class #{type.class_name}, expected Path" %}
        {% end %}

        {% if !%w{Int64 Float64 String Bool Nil}.includes?(type.names.first.stringify) %}
            {% raise "Invalid type #{type.names.first}" %}
        {% end %}

        %cond = ->(v : Array({{type}})){
          {{c}}
        }

        %rules[{{name}}] = Kontrol::{{rule}}{{type}}.new(:{{n}}, %cond)

      {% end %}

      %rules
    end

    macro nested(name, &block)
      _push {{name}}
      {% if block.class_name != "Nop" %}
        {{block.body}}
      {% end %}
      _pop
    end

    def _push_validator(validator : Validator)
      @validators.last << validator
    end

    def _push(name)
      @path << name
      @validators.push([] of Validator)
    end

    def _pop
      @validators.pop
      @path.pop
    end

    # def _add(name, rule)
    #   full_path = @path + [name]
    #   @rules[full_path] ||= [] of AbstractRule
    #   @rules[full_path] << rule
    # end

    def result
      HashValidator.new(rules)
    end
  end
end
