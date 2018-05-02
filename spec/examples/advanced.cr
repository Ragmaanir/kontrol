val, _ = object(
  {
    my_book: v["author"].as_s == v["book"]["author"].as_s,
  },
  author: String,
  book: object(
    author: String
  )
)

assert val.call(json(
  author: "Bob"
)) == {"book" => [:required]}

assert val.call(json(
  author: "Bob",
  book: {
    author: 1337,
  }
)) == {"book.author" => [:type]}

assert val.call(json(
  author: "Bob",
  book: {
    author: "Bobby",
  }
)) == {"@" => [:my_book]}

assert val.call(json(
  author: "Bob",
  book: {
    author: "Bob",
  }
)).empty?
