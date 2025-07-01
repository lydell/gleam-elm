import elm/html.{type Html}
import elm/json/decode.{type Decoder}
import elm/platform.{type Program}
import elm/platform/cmd.{type Cmd}
import elm/platform/sub.{type Sub}

@external(javascript, "./debugger.ffi.mjs", "_Debugger_element")
pub fn element(
  flags_decoder flags_decoder: Decoder(flags),
  init init: fn(flags) -> #(model, Cmd(msg)),
  view view: fn(model) -> Html(msg),
  update update: fn(msg, model) -> #(model, Cmd(msg)),
  subscriptions subscriptions: fn(model) -> Sub(msg),
  effect_managers effect_managers: List(platform.EffectManager),
) -> Program(flags, model, msg)
