import elm/html.{type Html}
import elm/platform.{type Program}
import elm/platform/cmd.{type Cmd}
import elm/platform/sub.{type Sub}
import gleam/dynamic

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
