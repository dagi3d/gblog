# gblog

[![Package Version](https://img.shields.io/hexpm/v/gblog)](https://hex.pm/packages/gblog)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://gblog.hexdocs.pm/)


## Installation
```
gleam add gblog@1
gleam add gleam_javascript # to avoid gleam compiler warning
gleam add glen             # to avoid gleam compiler warning
```

```
nodeLinker: hoisted
allowBuilds:
  '@parcel/watcher': true
  esbuild: true
packages:
  - ./build/packages/gblog/priv/
```

```sh
    pnpm install
```


```gleam
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
```

