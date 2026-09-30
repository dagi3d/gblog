import gblog/post
import gblog/post_repository
import gleam/dynamic.{type Dynamic}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/result

@external(javascript, "./ffi/notion.mjs", "load_posts")
fn load_posts() -> Promise(Dynamic)

pub fn main() -> Promise(Nil) {
  use posts <- promise.map(post.build(load_posts))
  let _ = post_repository.clear()

  let assert Ok(posts) = posts
  posts
  |> list.each(fn(post) { post_repository.save_post(post) })

  let _ =
    post_repository.find_all_by_tag("gleam", only_published: False)
    |> result.unwrap([])
    |> list.first()
  Nil
}
