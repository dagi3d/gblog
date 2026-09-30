import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/json.{type Json}

pub type Post {
  Post(
    title: String,
    status: String,
    path: String,
    tags: List(String),
    excerpt: String,
    content: String,
    published_at: String,
    year: Int,
  )
}

fn page_decoder() -> decode.Decoder(Post) {
  use title <- decode.field("title", decode.string)
  use status <- decode.field("status", decode.string)
  use path <- decode.field("path", decode.string)
  use tags <- decode.field("tags", decode.list(decode.string))
  use excerpt <- decode.field("excerpt", decode.string)
  use content <- decode.field("content", decode.string)
  use published_at <- decode.field("published_at", decode.string)

  let year = 2026
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

pub fn build(load_posts: fn() -> Promise(Dynamic)) {
  use result <- promise.map(load_posts())
  decode.run(result, decode.list(page_decoder()))
}

pub fn to_json(post: Post) -> Json {
  json.object([
    #("title", json.string(post.title)),
    #("status", json.string(post.status)),
    #("path", json.string(post.path)),
    #("tags", json.array(post.tags, json.string)),
    #("excerpt", json.string(post.excerpt)),
    #("content", json.string(post.content)),
    #("published_at", json.string(post.published_at)),
  ])
}

pub fn tags_to_json(tags: List(String)) -> String {
  json.array(tags, json.string)
  |> json.to_string
}
