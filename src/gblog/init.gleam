import gleam/io
import gleam/result
import simplifile

pub fn main() -> Result(Nil, simplifile.FileError) {
  use cwd <- result.try(simplifile.current_directory())
  let src_dir = cwd <> "/build/packages/gblog/priv/stubs"

  // workaround for demo
  let src_dir = case simplifile.exists(src_dir, True) {
    Ok(True) -> src_dir
    Ok(False) -> cwd <> "/../priv/stubs"
    Error(_) -> src_dir
  }

  let _ = copy(src_dir, "/templates", cwd)
  let _ = copy(src_dir, "/package.json", cwd)
  let _ = copy(src_dir, "/pnpm-workspace.yaml", cwd)
  let _ = copy(src_dir, "/blog.db", cwd)
}

fn copy(src_dir, stub, dst_dir) {
  let src = src_dir <> stub
  let dst = dst_dir <> stub
  use should_copy <- result.try(is_missing_or_empty(dst))
  use is_directory <- result.try(simplifile.is_directory(src))

  let _ = case should_copy, is_directory {
    True, True -> simplifile.copy_directory(at: src, to: dst)
    True, False -> simplifile.copy_file(at: src, to: dst)
    False, _ -> {
      io.println(dst <> " already exists. It won't be overriden")
      Ok(Nil)
    }
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
