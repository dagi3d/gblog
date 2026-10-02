import { fileURLToPath } from "node:url";
import path from "node:path";

// Resolves to this package's own `priv/templates`, regardless of which
// project's working directory `init` is run from.
export function templates_source_directory() {
  const ffiDir = path.dirname(fileURLToPath(import.meta.url));
  return path.join(ffiDir, "..", "..", "priv", "templates");
}
