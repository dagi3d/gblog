import gblog/post.{type Post, Post}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import sqlight
import tempo
import tempo/datetime
import youid/uuid

pub fn clear() {
  use conn <- sqlight.with_connection("./blog.db")
  "DELETE FROM posts"
  |> sqlight.exec(conn)
}

pub fn save_post(post: Post) {
  use conn <- sqlight.with_connection("./blog.db")

  let _ =
    "insert into posts 
      (id, title, status, path, tags, excerpt, content, published_at) 
        values 
      (?, ?, ?, ?, ?, ?, ?, ?)"
    |> sqlight.query(
      conn,
      [
        sqlight.text(new_id()),
        sqlight.text(post.title),
        sqlight.text(post.status),
        sqlight.text(post.path),
        sqlight.text(post.tags_to_json(post.tags)),
        sqlight.text(post.excerpt),
        sqlight.text(post.content),
        sqlight.text(post.published_at),
      ],
      decode.success(""),
    )
}

pub fn find_all_by_tag(
  tag: String,
  only_published only_published: Bool,
) -> Result(List(Post), sqlight.Error) {
  use conn <- sqlight.with_connection("./blog.db")

  let query =
    select()
    |> string.append("from posts, json_each(posts.tags)")
    |> string.append("where json_each.value = ?")
    |> with_status(only_published)
    |> order()

  let result =
    query
    |> sqlight.query(conn, [sqlight.text(tag)], post_decoder())

  result
}

pub fn find_by_path(path: String) {
  use conn <- sqlight.with_connection("./blog.db")

  let result =
    select()
    |> string.append("from posts where path = ?")
    |> sqlight.query(conn, [sqlight.text(path)], post_decoder())
    |> result.unwrap([])
    |> list.first()

  result
}

pub fn find_all(
  only_published only_published: Bool,
) -> Result(List(Post), sqlight.Error) {
  use conn <- sqlight.with_connection("./blog.db")

  let query =
    select()
    |> string.append("from posts ")
    |> string.append("where 1 = 1 ")
    |> with_status(only_published)
    |> order()

  let result =
    query
    |> sqlight.query(conn, [], post_decoder())

  result
}

fn select() -> String {
  "select posts.title, posts.status, posts.path, posts.tags, posts.excerpt, posts.content, posts.published_at "
}

fn order(query: String) -> String {
  query |> string.append(" order by published_at desc")
}

fn with_status(query: String, only_published: Bool) -> String {
  case only_published {
    True -> query <> " and status = 'published'"
    _ -> query
  }
}

fn new_id() -> String {
  uuid.v7()
  |> uuid.to_string()
}

// TODO: have single decoder. see post.page_decoder
fn post_decoder() -> decode.Decoder(Post) {
  use title <- decode.field(0, decode.string)
  use status <- decode.field(1, decode.string)
  use path <- decode.field(2, decode.string)
  use tags <- decode.field(3, decode.string)
  use excerpt <- decode.field(4, decode.string)
  use content <- decode.field(5, decode.string)
  use published_at <- decode.field(6, decode.string)

  let tags = tags_decoder(tags)

  let year =
    datetime.literal(published_at <> "T00:00:00Z")
    |> datetime.format(tempo.Custom("YYYY"))
    |> int.parse()
    |> result.unwrap(2026)

  decode.success(Post(
    title:,
    status:,
    path:,
    tags:,
    excerpt:,
    content:,
    published_at:,
    year:,
  ))
}

fn tags_decoder(input: String) -> List(String) {
  let decoder = decode.list(decode.string)
  let assert Ok(tags) = json.parse(input, decoder)
  tags
}
