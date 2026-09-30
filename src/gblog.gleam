import gblog/context
import gleam/javascript/promise.{type Promise}
import glen

pub fn start(
  port: Int,
  handle_request: fn(glen.Request, context.Ctx) -> Promise(glen.Response),
) {
  let ctx = context.new()
  glen.serve(port, fn(r: glen.Request) { handle_request(r, ctx) })
}

@external(javascript, "./gblog/ffi/util.mjs", "is_prod")
pub fn is_prod() -> Bool
