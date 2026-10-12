import { parse } from "jsr:@std/toml@^1";

const config = parse(await Deno.readTextFile(new URL("./gleam.toml", import.meta.url)));
const name = config.name;

const [command] = Deno.args;

switch (command) {
  case "start": {
    const { main } = await import(`./build/dev/javascript/${name}/blog.mjs`);
    main();
    break;
  }
  case "sync": {
    const { main } = await import("./build/dev/javascript/gblog/gblog/sync.mjs");
    await main();
    break;
  }
  default:
    console.error("Usage: deno entry.mjs start|sync");
    Deno.exit(1);
}

