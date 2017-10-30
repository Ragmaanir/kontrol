module Kontrol
  class Violation
    # JSON.mapping(
    #   # path: Array(String),
    #   key: String,
    #   errors: Array(String)
    # )

    getter key : String
    getter rule : AbstractRule
    getter errors : Array(String)

    def initialize(@key, @rule, @errors)
    end

    # def path : Array(String)
    #   key.split(".")
    # end
  end
end
