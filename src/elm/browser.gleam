import elm/html.{type Html}
import elm/json/decode.{type Decoder}
import elm/platform.{type Program}
import elm/platform/cmd.{type Cmd}
import elm/platform/sub.{type Sub}

pub type Element(flags, model, msg) {
  Element(
    flags_decoder: Decoder(flags),
    init: fn(flags) -> #(model, Cmd(msg)),
    view: fn(model) -> Html(msg),
    update: fn(msg, model) -> #(model, Cmd(msg)),
    subscriptions: fn(model) -> Sub(msg),
    effect_managers: List(platform.Manager),
  )
}

@external(javascript, "./browser.ffi.mjs", "_Browser_element")
pub fn element(impl: Element(flags, model, msg)) -> Program(flags, model, msg)
