import gleam/io
import gleam/result
import simplifile

/// Copies the default templates into the consuming project, so they can be
/// customized. Does nothing if a non-empty `templates` directory already
/// exists.
pub fn main() -> Result(Nil, simplifile.FileError) {
  use cwd <- result.try(simplifile.current_directory())
  let src_dir = cwd <> "/build/packages/gblog/priv/stubs"

  let _ = copy(src_dir, "/templates", cwd)
  let _ = copy(src_dir, "/pnpm-workspace.yaml", cwd)
  let _ = copy(src_dir, "/blog.db", cwd)
}

fn copy(src_dir, stub, dst_dir) {
  let src = src_dir <> stub
  let dst = dst_dir <> stub
  use should_copy <- result.try(is_missing_or_empty(dst))
  use is_directory <- result.try(simplifile.is_directory(src))

  echo #(src, dst, should_copy)
  let _ = case should_copy, is_directory {
    True, True -> simplifile.copy_directory(at: src, to: dst)
    True, False -> simplifile.copy_file(at: src, to: dst)
    False, _ -> Ok(Nil)
  }
}

fn is_missing_or_empty(path: String) -> Result(Bool, simplifile.FileError) {
  use exists <- result.try(simplifile.exists(path, True))
  use is_directory <- result.try(simplifile.is_directory(path))

  case exists, is_directory {
    // doesn't exist
    False, _ -> Ok(True)
    // exists and is a directory
    True, True -> {
      use entries <- result.try(simplifile.read_directory(path))
      Ok(entries == [])
    }
    // otherwise
    _, _ -> Ok(False)
  }
}
