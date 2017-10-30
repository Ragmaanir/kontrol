module Kontrol
  class ValidatorBuilder
    @path : Array(Symbol)
    getter rules : Hash(Array(Symbol), Array(AbstractRule))

    def initialize
      @path = [] of Symbol
      @rules = {} of Array(Symbol) => Array(AbstractRule)
    end

    def build
      with self yield
    end

    macro create_rules(**validations)
      {% if validations %}
        {% for n, c in validations %}

          {% if type.class_name == "Path" %}
            {% if %w{Int64 Float64 String Bool Nil}.includes?(type.names.first.stringify) %}
              %cond = ->(v : {{type}}){
                {{c}}
              }

              _add({{name}}, Kontrol::PrimitiveRule{{type}}.new(:{{n}}, %cond))
            {% else %}
              {% raise "tset" %}
            {% end %}
          {% elsif type.class_name == "Generic" %}
            %cond = ->(v : {{type}}){ {{c}} }

            _add({{name}}, Kontrol::ArrayRule({{type}}).new(:{{n}}, %cond))
          {% else %}
            {% raise type.class_name %}
          {% end %}
        {% end %}
      {% end %}
    end

    macro general_rule(name, **validations, &block)
    end

    macro array(name, type, **validations, &block)
      create_rules(type: ->(arr : Array(JSON::Type)) { v.all(&.is_a?({{type}})) })
      create_rules({{validations}})

      _push {{name}}
      {% if block.class_name != "Nop" %}
        {{block.body}}
      {% end %}
      _pop
    end

    macro array(name, **validations, &block)
      create_rules({{validations}})

      _push {{name}}
      {% if block.class_name != "Nop" %}
        {{block.body}}
      {% end %}
      _pop
    end

    macro primitive(name, type, **validations, &block)
      create_rules({{validations}})

      _push {{name}}
      {% if block.class_name != "Nop" %}
        {{block.body}}
      {% end %}
      _pop
    end

    macro required(name, type = Hash(Symbol, JSON::Type), **validations, &block)
      %req_cond = ->(v : {{type}}){ v != nil }
      _add({{name}}, Kontrol::Rule({{type}}).new(:required, %req_cond))

      {% if validations %}
        {% for n, c in validations %}

          {% if type.class_name == "Path" %}
            {% if %w{Int64 Float64 String Bool Nil}.includes?(type.names.first.stringify) %}
              %cond = ->(v : {{type}}){
                {{c}}
              }

              _add({{name}}, Kontrol::PrimitiveRule{{type}}.new(:{{n}}, %cond))
            {% else %}
              {% raise "tset" %}
            {% end %}
          {% elsif type.class_name == "Generic" %}
            %cond = ->(v : {{type}}){ {{c}} }

            _add({{name}}, Kontrol::ArrayRule({{type}}).new(:{{n}}, %cond))

            {% if false %}_add({{name}}, Kontrol::Rule({{type}}).new(:{{n}}, %cond)){% end %}
          {% else %}
            {% raise type.class_name %}
          {% end %}
        {% end %}
      {% end %}

      _push {{name}}
      {% if block.class_name != "Nop" %}
        {{block.body}}
      {% end %}
      _pop
    end

    # def required(name, type : T.class, validations : Hash(Symbol, T -> Bool), &block) forall T
    #   @path << name
    #   validations.each do |name, condition|
    #     _add(name, Rule.new(condition))
    #   end
    #   with self yield
    # end

    def _push(name)
      @path << name
    end

    def _pop
      @path.pop
    end

    # def _with_nesting(name, &block)
    #   @path << name

    #   with self yield

    #   @path.pop
    # end

    def _add(name, rule)
      full_path = @path + [name]
      @rules[full_path] ||= [] of AbstractRule
      @rules[full_path] << rule
    end

    def result
      Validator.new(rules)
    end
  end
end
