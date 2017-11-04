module Kontrol
  class Violation
    getter path : Path
    getter name : Symbol

    # getter rule : AbstractRule?
    # getter errors : Array(String)

    # def initialize(@name, @path, @rule = nil, @errors = [] of String)
    # end

    def initialize(@name, @path)
    end
  end
end
