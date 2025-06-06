import gleam/dynamic
import gleam/io
import gleam/string

@external(javascript, "./elm_compat.ffi.mjs", "getText")
fn get_text() -> string

pub fn main() -> Nil {
  io.println("Hello from elm_compat! " <> get_text())
}

pub fn add(x: Int, y: Int) -> Int {
  x + y
}

pub fn init(arg: dynamic.Dynamic) {
  fn() {
    io.println(
      "Initializing Elm compatibility module...: " <> string.inspect(arg),
    )
  }
}
