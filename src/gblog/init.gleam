import gleam/result
import simplifile

const source = "priv/templates"

const destination = "templates"

/// Copies the default templates into the consuming project, so they can be
/// customized. Does nothing if a non-empty `templates` directory already
/// exists.
pub fn main() -> Result(Nil, simplifile.FileError) {
  use should_copy <- result.try(is_missing_or_empty(destination))

  case should_copy {
    True -> simplifile.copy_directory(at: source, to: destination)
    False -> Ok(Nil)
  }
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
