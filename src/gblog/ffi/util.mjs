export function is_prod() {
  return Deno.env.get("APP_ENV") == "production";
}

