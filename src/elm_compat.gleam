import elm/browser
import elm/json/decode
import elm/json/encode
import elm/platform
import elm/platform/cmd.{type Cmd}
import elm/platform/sub.{type Sub}
import elm/task
import elm/time
import elm/virtual_dom
import gleam/dynamic
import gleam/function
import gleam/int
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

pub fn html_program() {
  virtual_dom.init(
    virtual_dom.node(
      "a",
      [virtual_dom.attribute("href", "https://elm-lang.org/")],
      [virtual_dom.text("Elm!")],
    ),
  )
}

const on_count_name = "onCount"

fn on_count(count: Int) -> Cmd(a) {
  platform.leaf_cmd(on_count_name, count)
}

fn on_count_manager() -> platform.Manager {
  platform.outgoing_port(on_count_name, encode.int)
}

const on_js_message_name = "onJsMessage"

fn on_js_message() -> Sub(a) {
  platform.leaf_sub(on_js_message_name, fn(js_message) {
    echo js_message
    Nil
  })
}

fn on_count_message_manager() -> platform.Manager {
  platform.incoming_port(on_js_message_name, decode.string())
}

pub fn element_program() {
  browser.element(
    browser.Element(
      flags_decoder: decode.succeed(Nil),
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
            2 -> task.perform(function.identity, task.succeed(Nil))
            _ -> on_count(model + 1)
          })
        }
      },
      subscriptions: fn(model) {
        case model {
          6 | 7 | 8 | 9 -> time.every(1000.0, fn(_) { Nil })
          _ -> on_js_message()
        }
      },
      effect_managers: [
        task.manager(),
        time.manager(),
        on_count_manager(),
        on_count_message_manager(),
      ],
    ),
  )
}
