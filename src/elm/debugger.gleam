import elm/browser.{type Document}
import elm/html.{type Html}
import elm/json/decode.{type Decoder}
import elm/platform.{type Program}
import elm/platform/cmd.{type Cmd}
import elm/platform/sub.{type Sub}

pub fn sandbox(
  init init: model,
  view view: fn(model) -> Html(msg),
  update update: fn(msg, model) -> model,
) -> Program(Nil, model, msg) {
  element(
    flags_decoder: decode.succeed(Nil),
    init: fn(_) { #(init, cmd.none()) },
    view: view,
    update: fn(msg, model) { #(update(msg, model), cmd.none()) },
    subscriptions: fn(_) { sub.none() },
    effect_managers: [],
  )
}

@external(javascript, "./debugger.ffi.mjs", "_Debugger_element")
pub fn element(
  flags_decoder flags_decoder: Decoder(flags),
  init init: fn(flags) -> #(model, Cmd(msg)),
  view view: fn(model) -> Html(msg),
  update update: fn(msg, model) -> #(model, Cmd(msg)),
  subscriptions subscriptions: fn(model) -> Sub(msg),
  effect_managers effect_managers: List(platform.EffectManager),
) -> Program(flags, model, msg)

@external(javascript, "./debugger.ffi.mjs", "_Debugger_document")
pub fn document(
  flags_decoder flags_decoder: Decoder(flags),
  init init: fn(flags) -> #(model, Cmd(msg)),
  view view: fn(model) -> Document(msg),
  update update: fn(msg, model) -> #(model, Cmd(msg)),
  subscriptions subscriptions: fn(model) -> Sub(msg),
  effect_managers effect_managers: List(platform.EffectManager),
) -> Program(flags, model, msg)
// TODO: application
