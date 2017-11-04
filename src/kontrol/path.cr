module Kontrol
  class Path
    def self.root
      Path.new("")
    end

    getter raw_path : String

    def initialize(@raw_path)
    end

    def index(i : Int32 | Int64)
      Path.new(raw_path + "[#{i}]")
    end

    def child(name : String)
      Path.new(raw_path + ".#{name}")
    end

    def_equals_and_hash :raw_path

    def inspect(io : IO)
      io << "Path(#{raw_path})"
    end
  end
end
