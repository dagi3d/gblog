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
# this will copy the following files
#
# ├── blog.db
# ├── package.json
# ├── pnpm-workspace.yaml
# └── templates
#     ├── index.html.pug
#     ├── layout.html.pug
#     ├── mixins.pug
#     ├── post.html.pug
#     └── posts.html.pug
#
# existing files are never overwritten

gleam run -m gblog/init
```

```sh
pnpm install
```

The generated `package.json` and `pnpm-workspace.yaml` make gblog's npm
dependencies (pug, the Notion client, sass, esbuild, ...) resolvable from your
project root. Deno refuses bare imports such as `pug` when the project root has
no `package.json`, so keep both files even if you don't add npm dependencies of
your own.

## Sync posts
```
# ensure following env variables are available
# .env or .env.local files are support
NOTION_API_KEY=
NOTION_DATA_SOURCE_ID=
```

```bash
gleam run -m gblog/sync
```

## Wire your app

```toml
[javascript]
runtime = "deno"

[javascript.deno]
# net:       the http server
# read/write: sqlite database and templates
# env:       APP_ENV, NOTION_API_KEY, NOTION_DATA_SOURCE_ID
# sys:       pug reads $HOME through its `resolve` dependency
allow_net = true
allow_read = true
allow_write = true
allow_env = true
allow_sys = true
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
