import elm/browser/navigation
import elm/html.{type Html}
import elm/json/decode.{type Decoder}
import elm/platform.{type Program}
import elm/platform/cmd.{type Cmd}
import elm/platform/sub.{type Sub}
import elm/url.{type Url}

pub type Sandbox(model, msg) {
  Sandbox(
    init: model,
    view: fn(model) -> Html(msg),
    update: fn(msg, model) -> model,
  )
}

pub fn sandbox(impl: Sandbox(model, msg)) -> Program(Nil, model, msg) {
  element(
    Element(
      flags_decoder: decode.succeed(Nil),
      init: fn(_) { #(impl.init, cmd.none()) },
      view: impl.view,
      update: fn(msg, model) { #(impl.update(msg, model), cmd.none()) },
      subscriptions: fn(_) { sub.none() },
      effect_managers: [],
    ),
  )
}

pub type Element(flags, model, msg) {
  Element(
    flags_decoder: Decoder(flags),
    init: fn(flags) -> #(model, Cmd(msg)),
    view: fn(model) -> Html(msg),
    update: fn(msg, model) -> #(model, Cmd(msg)),
    subscriptions: fn(model) -> Sub(msg),
    effect_managers: List(platform.EffectManager),
  )
}

@external(javascript, "./browser.ffi.mjs", "_Browser_element")
pub fn element(impl: Element(flags, model, msg)) -> Program(flags, model, msg)

pub type Document(msg) {
  Document(title: String, body: List(Html(msg)))
}

pub type Application(flags, model, msg) {
  Application(
    flags_decoder: Decoder(flags),
    init: fn(flags, Url, navigation.Key) -> #(model, Cmd(msg)),
    view: fn(model) -> Document(msg),
    update: fn(msg, model) -> #(model, Cmd(msg)),
    subscriptions: fn(model) -> Sub(msg),
    on_url_request: fn(UrlRequest) -> msg,
    on_url_change: fn(Url) -> msg,
    effect_managers: List(platform.EffectManager),
  )
}

@external(javascript, "./browser.ffi.mjs", "_Browser_application")
pub fn application(
  impl: Application(flags, model, msg),
) -> Program(flags, model, msg)

pub type UrlRequest {
  Internal(Url)
  External(String)
}
