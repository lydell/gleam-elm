import core/platform.{type Program}
import core/platform/cmd.{type Cmd}
import core/platform/sub.{type Sub}
import gleam/dynamic
import html/html.{type Html}

pub type Element(model, msg) {
  Element(
    init: fn(dynamic.Dynamic) -> #(model, Cmd(msg)),
    view: fn(model) -> Html(msg),
    update: fn(msg, model) -> #(model, Cmd(msg)),
    subscriptions: fn(model) -> Sub(msg),
    effect_managers: List(#(String, platform.Manager)),
  )
}

@external(javascript, "./browser.ffi.mjs", "_Browser_element")
pub fn element(impl: Element(model, msg)) -> Program(model, msg)
