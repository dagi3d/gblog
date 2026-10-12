import gblog
import gblog/context
import gblog/router
import gleam/javascript/promise.{type Promise}
import glen

pub fn main() {
  gblog.start(8000, handle_request)
}

fn handle_request(
  req: glen.Request,
  ctx: context.Ctx,
) -> Promise(glen.Response) {
  router.default_routes(req, ctx)
}
