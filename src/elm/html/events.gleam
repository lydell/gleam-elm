//// It is often helpful to create an [Custom Type][] so you can have many different kinds
//// of events as seen in the [TodoMVC][] example.
////
//// [Custom Type]: https://guide.elm-lang.org/types/custom_types.html
//// [TodoMVC]: https://github.com/evancz/elm-todomvc/blob/master/Todo.elm
////
//// # Mouse
//// @docs onClick, onDoubleClick,
////       onMouseDown, onMouseUp,
////       onMouseEnter, onMouseLeave,
////       onMouseOver, onMouseOut
////
//// # Forms
//// @docs onInput, onCheck, onSubmit
////
//// # Focus
//// @docs onBlur, onFocus
////
//// # Custom
//// @docs on, stopPropagationOn, preventDefaultOn, custom
////
//// ## Custom Decoders
//// @docs targetValue, targetChecked, keyCode

import elm/html.{type Attribute}
import elm/json/decode.{type Decoder}
import elm/virtual_dom

// MOUSE EVENTS

///
pub fn on_click(msg: msg) {
  on("click", decode.succeed(msg))
}

///
pub fn on_double_click(msg: msg) {
  on("dblclick", decode.succeed(msg))
}

///
pub fn on_mouse_down(msg: msg) {
  on("mousedown", decode.succeed(msg))
}

///
pub fn on_mouse_up(msg: msg) {
  on("mouseup", decode.succeed(msg))
}

///
pub fn on_mouse_enter(msg: msg) {
  on("mouseenter", decode.succeed(msg))
}

///
pub fn on_mouse_leave(msg: msg) {
  on("mouseleave", decode.succeed(msg))
}

///
pub fn on_mouse_over(msg: msg) {
  on("mouseover", decode.succeed(msg))
}

///
pub fn on_mouse_out(msg: msg) {
  on("mouseout", decode.succeed(msg))
}

// FORM EVENTS

/// Detect [input](https://developer.mozilla.org/en-US/docs/Web/Events/input)
/// events for things like text fields or text areas.
///
/// For more details on how `onInput` works, check out [`targetValue`](#targetValue).
///
/// **Note 1:** It grabs the **string** value at `event.target.value`, so it will
/// not work if you need some other information. For example, if you want to track
/// inputs on a range slider, make a custom handler with [`on`](#on).
///
/// **Note 2:** It uses `stopPropagationOn` internally to always stop propagation
/// of the event. This is important for complicated reasons explained [here][1] and
/// [here][2].
///
/// [1]: /packages/elm/virtual-dom/latest/VirtualDom#Handler
/// [2]: https://github.com/elm/virtual-dom/issues/125
pub fn on_input(tagger: fn(String) -> msg) -> Attribute(msg) {
  stop_propagation_on(
    "input",
    decode.map(decode.map(target_value(), tagger), always_stop),
  )
}

fn always_stop(x: a) -> #(a, Bool) {
  #(x, True)
}

/// Detect [change](https://developer.mozilla.org/en-US/docs/Web/Events/change)
/// events on checkboxes. It will grab the boolean value from `event.target.checked`
/// on any input event.
///
/// Check out [`targetChecked`](#targetChecked) for more details on how this works.
pub fn on_check(tagger: fn(Bool) -> msg) -> Attribute(msg) {
  on("change", decode.map(target_checked(), tagger))
}

/// Detect a [submit](https://developer.mozilla.org/en-US/docs/Web/Events/submit)
/// event with [`preventDefault`](https://developer.mozilla.org/en-US/docs/Web/API/Event/preventDefault)
/// in order to prevent the form from changing the page’s location. If you need
/// different behavior, create a custom event handler.
pub fn on_submit(msg: msg) -> Attribute(msg) {
  prevent_default_on(
    "submit",
    decode.map(decode.succeed(msg), always_prevent_default),
  )
}

fn always_prevent_default(msg: msg) -> #(msg, Bool) {
  #(msg, True)
}

// FOCUS EVENTS

///
pub fn on_blur(msg: msg) {
  on("blur", decode.succeed(msg))
}

///
pub fn on_focus(msg: msg) {
  on("focus", decode.succeed(msg))
}

// CUSTOM EVENTS

/// Create a custom event listener. Normally this will not be necessary, but
/// you have the power! Here is how `onClick` is defined for example:
///
///     import Json.Decode as Decode
///
///     onClick : msg -> Attribute msg
///     onClick message =
///       on "click" (Decode.succeed message)
///
/// The first argument is the event name in the same format as with JavaScript's
/// [`addEventListener`][aEL] function.
///
/// The second argument is a JSON decoder. Read more about these [here][decoder].
/// When an event occurs, the decoder tries to turn the event object into an Elm
/// value. If successful, the value is routed to your `update` function. In the
/// case of `onClick` we always just succeed with the given `message`.
///
/// If this is confusing, work through the [Elm Architecture Tutorial][tutorial].
/// It really helps!
///
/// [aEL]: https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/addEventListener
/// [decoder]: /packages/elm/json/latest/Json-Decode
/// [tutorial]: https://github.com/evancz/elm-architecture-tutorial/
///
/// **Note:** This creates a [passive][] event listener, enabling optimizations for
/// touch, scroll, and wheel events in some browsers.
///
/// [passive]: https://github.com/WICG/EventListenerOptions/blob/gh-pages/explainer.md
pub fn on(event: String, decoder: Decoder(msg)) -> Attribute(msg) {
  virtual_dom.on(event, virtual_dom.Normal(decoder))
}

/// Create an event listener that may [`stopPropagation`][stop]. Your decoder
/// must produce a message and a `Bool` that decides if `stopPropagation` should
/// be called.
///
/// [stop]: https://developer.mozilla.org/en-US/docs/Web/API/Event/stopPropagation
///
/// **Note:** This creates a [passive][] event listener, enabling optimizations for
/// touch, scroll, and wheel events in some browsers.
///
/// [passive]: https://github.com/WICG/EventListenerOptions/blob/gh-pages/explainer.md
pub fn stop_propagation_on(
  event: String,
  decoder: Decoder(#(msg, Bool)),
) -> Attribute(msg) {
  virtual_dom.on(event, virtual_dom.MayStopPropagation(decoder))
}

/// Create an event listener that may [`preventDefault`][prevent]. Your decoder
/// must produce a message and a `Bool` that decides if `preventDefault` should
/// be called.
///
/// For example, the `onSubmit` function in this library *always* prevents the
/// default behavior:
///
/// [prevent]: https://developer.mozilla.org/en-US/docs/Web/API/Event/preventDefault
///
///     onSubmit : msg -> Attribute msg
///     onSubmit msg =
///       preventDefaultOn "submit" (Json.map alwaysPreventDefault (Json.succeed msg))
///
///     alwaysPreventDefault : msg -> ( msg, Bool )
///     alwaysPreventDefault msg =
///       ( msg, True )
pub fn prevent_default_on(
  event: String,
  decoder: Decoder(#(msg, Bool)),
) -> Attribute(msg) {
  virtual_dom.on(event, virtual_dom.MayPreventDefault(decoder))
}

/// Create an event listener that may [`stopPropagation`][stop] or
/// [`preventDefault`][prevent].
///
/// [stop]: https://developer.mozilla.org/en-US/docs/Web/API/Event/stopPropagation
/// [prevent]: https://developer.mozilla.org/en-US/docs/Web/API/Event/preventDefault
/// [handler]: https://package.elm-lang.org/packages/elm/virtual-dom/latest/VirtualDom#Handler
///
/// **Note:** Check out the lower-level event API in `elm/virtual-dom` for more
/// information on exactly how events work, especially the [`Handler`][handler]
/// docs.
pub fn custom(
  event: String,
  decoder: Decoder(virtual_dom.CustomHandler(msg)),
) -> Attribute(msg) {
  virtual_dom.on(event, virtual_dom.Custom(decoder))
}

// COMMON DECODERS

/// A `Json.Decoder` for grabbing `event.target.value`. We use this to define
/// `onInput` as follows:
///
///     import Json.Decode as Json
///
///     onInput : (String -> msg) -> Attribute msg
///     onInput tagger =
///       stopPropagationOn "input" <|
///         Json.map alwaysStop (Json.map tagger targetValue)
///
///     alwaysStop : a -> (a, Bool)
///     alwaysStop x =
///       (x, True)
///
/// You probably will never need this, but hopefully it gives some insights into
/// how to make custom event handlers.
pub fn target_value() -> Decoder(String) {
  decode.at(["target", "value"], decode.string())
}

/// A `Json.Decoder` for grabbing `event.target.checked`. We use this to define
/// `onCheck` as follows:
///
///     import Json.Decode as Json
///
///     onCheck : (Bool -> msg) -> Attribute msg
///     onCheck tagger =
///       on "input" (Json.map tagger targetChecked)
pub fn target_checked() -> Decoder(Bool) {
  decode.at(["target", "checked"], decode.bool())
}

/// A `Json.Decoder` for grabbing `event.keyCode`. This helps you define
/// keyboard listeners like this:
///
///     import Json.Decode as Json
///
///     onKeyUp : (Int -> msg) -> Attribute msg
///     onKeyUp tagger =
///       on "keyup" (Json.map tagger keyCode)
///
/// **Note:** It looks like the spec is moving away from `event.keyCode` and
/// towards `event.key`. Once this is supported in more browsers, we may add
/// helpers here for `onKeyUp`, `onKeyDown`, `onKeyPress`, etc.
pub fn key_code() -> Decoder(Int) {
  decode.field("keyCode", decode.int())
}
