import gleam/dict
import gleam/json

pub type Ctx {
  Ctx(data: dict.Dict(String, json.Json))
}

pub fn new() -> Ctx {
  Ctx(data: dict.new())
}

pub fn set(ctx: Ctx, key: String, value: json.Json) -> Ctx {
  Ctx(data: dict.insert(ctx.data, key, value))
}

pub fn to_json(ctx: Ctx) -> json.Json {
  json.object(dict.to_list(ctx.data))
}
