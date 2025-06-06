import gleam/dynamic
import gleam/io
import gleam/string

pub fn main() -> Nil {
  io.println("Hello from elm_compat!")
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
