module Kontrol
  abstract class AbstractRule
    abstract def name : Symbol

    def call(input : JSON::Type)
      false
    end
  end

  class Rule(T) < AbstractRule
    getter name : Symbol
    getter condition : T -> Bool

    def initialize(@name, @condition)
    end

    def call(input : JSON::Type)
      case input
      when T then condition.call(input)
      else        false
      end
    end
  end

  # class PrimitiveRule(T) < AbstractRule
  #   alias CLASSES = String.class | Int64.class | Float64.class | Bool.class | Nil.class

  #   getter name : Symbol
  #   getter type : CLASSES
  #   getter condition : T -> Bool

  #   def initialize(@name, @type, @condition)
  #   end

  #   def call(input : JSON::Type)
  #     if input.class = type
  #       case v = input.class
  #       when String  then condition.call(v)
  #       when Int64   then condition.call(v)
  #       when Float64 then condition.call(v)
  #       when Bool    then condition.call(v)
  #       when Nil     then condition.call(v)
  #       end
  #     end
  #   end
  # end

  PRIMITIVES = %w{String Int64 Float64 Bool Nil}

  {% for type in PRIMITIVES %}
    class PrimitiveRule{{type.id}} < AbstractRule
      getter name : Symbol
      getter condition : {{type.id}} -> Bool

      def initialize(@name, @condition)
      end

      def call(input : JSON::Type)
        if input.is_a?({{type.id}})
          condition.call(input)
        else
          false
        end
      end
    end
  {% end %}

  {% for type in PRIMITIVES %}
    class ArrayRule{{type.id}} < AbstractRule
      getter name : Symbol
      getter condition : Array({{type.id}}) -> Bool

      def initialize(@name, @condition)
      end

      def call(input : JSON::Type)
        if input.is_a?(Array(JSON::Type)) && input.all?(&.is_a?({{type.id}}))
          #condition.call(input.as(Array({{type.id}})))
          condition.call(input.map(&.as({{type.id}})))
        else
          false
        end
      end
    end
  {% end %}

  # class HashRule(T) < AbstractRule
  #   alias CLASSES = String.class | Int64.class | Float64.class | Bool.class | Nil.class

  #   getter name : Symbol
  #   getter type : CLASSES
  #   getter condition : T -> Bool

  #   def initialize(@name, @type, @condition)
  #   end

  #   def call(input : JSON::Type)
  #     if input.class = type
  #       case v = input.class
  #       when String  then condition.call(v.as(T))
  #       when Int64   then condition.call(v.as(T))
  #       when Float64 then condition.call(v.as(T))
  #       when Bool    then condition.call(v.as(T))
  #       when Nil     then condition.call(v.as(T))
  #       end
  #     end
  #   end
  # end
end
