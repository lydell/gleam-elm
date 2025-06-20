import browser/browser
import core/platform/cmd
import core/platform/sub
import core/task
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/string
import json/decode
import virtual_dom/virtual_dom

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

pub fn html_program() {
  virtual_dom.init(
    virtual_dom.node(
      "a",
      [virtual_dom.attribute("href", "https://elm-lang.org/")],
      [virtual_dom.text("Elm!")],
    ),
  )
}

pub fn element_program() {
  browser.element(
    browser.Element(
      init: fn(_) { #(0, cmd.none()) },
      view: fn(model) {
        virtual_dom.node(
          "button",
          [virtual_dom.on("click", virtual_dom.Normal(decode.succeed(Nil)))],
          [virtual_dom.text(int.to_string(model))],
        )
      },
      update: fn(msg, model) {
        case msg {
          Nil -> #(model + 1, case model {
            2 -> task.perform(fn(_) { Nil }, task.succeed(Nil))
            _ -> cmd.none()
          })
        }
      },
      subscriptions: fn(_) { sub.none() },
    ),
  )
}
