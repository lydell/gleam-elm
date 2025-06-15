import core/platform.{type Program}
import core/platform/cmd.{type Cmd}
import core/platform/sub.{type Sub}
import html/html.{type Html}

pub type Element(flags, model, msg) {
  Element(
    init: fn(flags) -> #(model, Cmd(msg)),
    view: fn(model) -> Html(msg),
    update: fn(msg, model) -> #(model, Cmd(msg)),
    subscriptions: fn(model) -> Sub(msg),
  )
}

@external(javascript, "./browser.ffi.mjs", "_Browser_element")
pub fn element(impl: Element(flags, model, msg)) -> Program(flags, model, msg)
