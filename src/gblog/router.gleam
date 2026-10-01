import gblog/context
import gblog/post.{type Post}
import gblog/post_repository
import gleam/dict
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import glen

@external(javascript, "./ffi/template.mjs", "template")
fn render_template(file: String, vars: Option(String)) -> String

@external(javascript, "./ffi/util.mjs", "is_prod")
fn is_prod() -> Bool

type ResponseType {
  HTML
  XML
}

type Response {
  Response(content: Result(String, RenderError), content_type: ResponseType)
}

type RenderError {
  NotFound
}

pub fn default_routes(
  req: glen.Request,
  ctx: context.Ctx,
  // next: fn(context.Ctx) -> Promise(glen.Response),
) -> Promise(glen.Response) {
  use <- glen.static(req, "static", "./public/static")

  // compiled assets
  use <- glen.static(req, "assets", "./public/assets")
  use <- glen.static(req, "favicon.png", "./public/favicon.png")

  use <- handle_websocket(req)
  use <- handle_blog(req, ctx)

  not_found()
  // next(ctx)
}

pub fn handle(
  req: glen.Request,
  ctx: context.Ctx,
  segments: List(String),
  template: String,
  next: fn(context.Ctx) -> Promise(glen.Response),
) -> Promise(glen.Response) {
  case glen.path_segments(req) == segments {
    True -> render_page(template, ctx)
    _ -> next(ctx)
  }
}

pub fn not_found() {
  glen.text("Not found", 404)
  |> promise.resolve
}

fn handle_websocket(
  req: glen.Request,
  next: fn() -> Promise(glen.Response),
) -> Promise(glen.Response) {
  case glen.path_segments(req) {
    ["__livereload"] ->
      glen.websocket(
        req,
        on_open: fn(_conn) { Nil },
        on_close: fn(_state) { Nil },
        on_event: fn(_conn, state, _msg) { state },
        with_conn: fn(_conn) { Nil },
      )
    _ -> next()
  }
}

fn handle_blog(
  req: glen.Request,
  ctx: context.Ctx,
  next: fn() -> Promise(glen.Response),
) -> Promise(glen.Response) {
  case glen.path_segments(req) {
    [] -> render_page("index.html", ctx)
    ["blog"] -> render_blog(ctx)
    ["blog", _, _, _, _] -> render_post(req.path, ctx)
    ["blog", "tag", tag] -> render_tag(tag, ctx)
    ["about"] -> render_page("about.html", ctx)
    ["rss.xml"] -> render_feed()
    _ -> next()
  }
}

fn render_blog(ctx: context.Ctx) {
  render_posts(None, "posts.html.pug", ctx, HTML)
}

fn render_tag(tag: String, ctx: context.Ctx) {
  render_posts(Some(tag), "posts.html.pug", ctx, HTML)
}

fn render_feed() {
  render_posts(None, "feed.xml.pug", context.new(), XML)
}

fn group_by_year_desc(posts: List(Post)) -> List(#(Int, List(Post))) {
  posts
  |> list.group(fn(post: Post) { post.year })
  |> dict.map_values(fn(_year, posts) {
    list.sort(posts, fn(a, b) { string.compare(b.published_at, a.published_at) })
  })
  |> dict.to_list()
  |> list.sort(fn(a, b) { int.compare(b.0, a.0) })
}

fn find_posts(tag: Option(String)) {
  let posts = case tag {
    Some(tag) -> post_repository.find_all_by_tag(tag, only_published: is_prod())
    None -> post_repository.find_all(only_published: is_prod())
  }

  posts
  |> result.unwrap([])
  |> group_by_year_desc()
}

fn render_posts(
  tag: Option(String),
  template: String,
  ctx: context.Ctx,
  content_type: ResponseType,
) {
  let posts = find_posts(tag)
  let posts_json =
    json.array(posts, fn(pair) {
      json.object([
        #("year", json.int(pair.0)),
        #("posts", json.array(pair.1, post.to_json)),
      ])
    })

  let vars = [
    #("posts", posts_json),
    #("tag", json.nullable(tag, json.string)),
  ]

  let out = case posts, tag {
    [], Some(_) -> Error(NotFound)
    _, _ -> Ok(render(template, ctx, vars))
  }

  render_response(Response(out, content_type))
}

fn render(
  template: String,
  ctx: context.Ctx,
  vars: List(#(String, json.Json)),
) {
  let ctx = ctx |> context.set("livereload", json.bool(!is_prod()))

  let vars =
    ctx.data
    |> dict.to_list
    |> list.append(vars)
    |> json.object
    |> json.to_string

  render_template("./templates/" <> template, Some(vars))
}

fn render_post(path: String, ctx) {
  let path = string.replace(path, "/blog", "")
  let assert Ok(post) = post_repository.find_by_path(path)

  let vars = [#("post", post.to_json(post))]

  let out = render("post.html.pug", ctx, vars)
  render_response(Response(Ok(out), HTML))
}

fn render_page(page: String, ctx: context.Ctx) {
  let out = render(page <> ".pug", ctx, [])
  render_response(Response(Ok(out), HTML))
}

fn render_response(response: Response) {
  let content_type = case response.content_type {
    HTML -> "text/html; charset=utf-8"
    XML -> "text/xml; charset=utf-8"
  }

  let #(content, status) = case response {
    Response(Ok(content), _) -> #(content, 200)
    Response(Error(NotFound), _) -> #("Not found", 404)
  }

  glen.text(content, status)
  |> glen.set_header("Content-type", content_type)
  |> promise.resolve
}
