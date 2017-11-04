module Kontrol
  abstract class AbstractRule
    def call(input : JSON::Type)
      false
    end
  end

  class ObjectRule < AbstractRule
    getter condition : Hash(String, JSON::Type) -> Bool

    def initialize(&@condition : Hash(String, JSON::Type) -> Bool)
    end

    def call(input : Hash(String, JSON::Type))
      condition.call(input)
    end
  end

  PRIMITIVES = %w{String Int64 Float64 Bool Nil}

  PRIMITIVE_TYPES_X = {
    String: String,
    Int:    Int64,
    Float:  Float64,
    Bool:   Bool,
  }

  {% for name, type in PRIMITIVE_TYPES_X %}
    class {{name.id}}Rule < AbstractRule
      getter condition : {{type.id}} -> Bool

      def initialize(&@condition : {{type.id}} -> Bool)
      end

      def call(input : {{type.id}})
        condition.call(input)
      end
    end
  {% end %}

  {% for name, type in PRIMITIVE_TYPES_X %}
    class {{name}}ArrayRule < AbstractRule
      getter name : Symbol
      getter condition : Array({{type.id}}) -> Bool

      def initialize(@name, @condition)
      end

      def call(input : JSON::Type)
        if input.is_a?(Array(JSON::Type)) && input.all?(&.is_a?({{type.id}}))
          condition.call(input.map(&.as({{type.id}})))
        else
          false
        end
      end
    end
  {% end %}
end
