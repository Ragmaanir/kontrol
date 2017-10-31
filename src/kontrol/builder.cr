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

    macro create_primitive_rules(name, type, **validations)
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

          _add({{name}}, Kontrol::PrimitiveRule{{type}}.new(:{{n}}, %cond))

      {% end %}
    end

    macro create_array_rules(name, type, **validations)
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

        _add({{name}}, Kontrol::ArrayRule{{type}}.new(:{{n}}, %cond))

      {% end %}
    end

    macro nested(name, &block)
      _push {{name}}
      {% if block.class_name != "Nop" %}
        {{block.body}}
      {% end %}
      _pop
    end

    macro array(name, type, **validations)
      create_array_rules({{name}}, {{type}}, type_check: v.all?(&.is_a?({{type}})))
      create_array_rules({{name}}, {{type}}, {{**validations}})
    end

    macro array(name, **validations, &block)
      create_array_rules(Array(JSON::Type), {{validations}})

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
      create_primitive_rules({{name}}, {{type}}, type_check: v.is_a?({{type}}))
      create_primitive_rules({{name}}, {{type}}, {{**validations}})
    end

    # macro required(name, type = Hash(Symbol, JSON::Type), **validations, &block)
    #   %req_cond = ->(v : {{type}}){ v != nil }
    #   _add({{name}}, Kontrol::Rule({{type}}).new(:required, %req_cond))

    #   {% if validations %}
    #     {% for n, c in validations %}

    #       {% if type.class_name == "Path" %}
    #         {% if %w{Int64 Float64 String Bool Nil}.includes?(type.names.first.stringify) %}
    #           %cond = ->(v : {{type}}){
    #             {{c}}
    #           }

    #           _add({{name}}, Kontrol::PrimitiveRule{{type}}.new(:{{n}}, %cond))
    #         {% else %}
    #           {% raise "tset" %}
    #         {% end %}
    #       {% elsif type.class_name == "Generic" %}
    #         %cond = ->(v : {{type}}){ {{c}} }

    #         _add({{name}}, Kontrol::ArrayRule({{type}}).new(:{{n}}, %cond))

    #         {% if false %}_add({{name}}, Kontrol::Rule({{type}}).new(:{{n}}, %cond)){% end %}
    #       {% else %}
    #         {% raise type.class_name %}
    #       {% end %}
    #     {% end %}
    #   {% end %}

    #   _push {{name}}
    #   {% if block.class_name != "Nop" %}
    #     {{block.body}}
    #   {% end %}
    #   _pop
    # end

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
