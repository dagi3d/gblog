import gleam/io
import gleam/result
import simplifile

const destination = "templates"

/// Copies the default templates into the consuming project, so they can be
/// customized. Does nothing if a non-empty `templates` directory already
/// exists.
pub fn main() -> Result(Nil, simplifile.FileError) {
  use cwd <- result.try(simplifile.current_directory())

  let source_dir = cwd <> "/build/packages/gblog/priv/templates"
  let source_dir = "/Users/borja/development/borja/gblog/priv/templates"
  let destination = cwd <> "/templates"

  echo #(source_dir, destination)
  use should_copy <- result.try(is_missing_or_empty(destination))

  let _ = case should_copy {
    True -> simplifile.copy_directory(at: source_dir, to: destination)
    False -> Ok(Nil)
  }

  case should_copy {
    True -> {
      io.println("Templates copied")
    }
    _ -> io.print_error("Directory ./templates is not empty")
  }
  Ok(Nil)
}

fn is_missing_or_empty(path: String) -> Result(Bool, simplifile.FileError) {
  use exists <- result.try(simplifile.is_directory(path))

  case exists {
    False -> Ok(True)
    True -> {
      use entries <- result.try(simplifile.read_directory(path))
      Ok(entries == [])
    }
  }
}
