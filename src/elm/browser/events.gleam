//// In JavaScript, information about the root of an HTML document is held in
//// the `document` and `window` objects. This module lets you create event
//// listeners on those objects for the following topics: [animation](#animation),
//// [keyboard](#keyboard), [mouse](#mouse), and [window](#window).
////
//// If there is something else you need, use [ports] to do it in JavaScript!
////
//// [ports]: https://guide.elm-lang.org/interop/ports.html

import elm/basics.{type Never}
import elm/browser/animation_manager
import elm/json/decode.{type Decoder}
import elm/platform
import elm/platform/sub.{type Sub}
import elm/process
import elm/task.{type Task}
import elm/time
import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/list

// ANIMATION

/// An animation frame triggers about 60 times per second. Get the POSIX time
/// on each frame. (See [`elm/time`](/packages/elm/time/latest) for more info on
/// POSIX times.)
///
/// **Note:** Browsers have their own render loop, repainting things as fast as
/// possible. If you want smooth animations in your application, it is helpful to
/// sync up with the browsers natural refresh rate. This hooks into JavaScript's
/// `requestAnimationFrame` function.
pub fn on_animation_frame(tagger: fn(time.Posix) -> msg) -> Sub(msg) {
  animation_manager.on_animation_frame(tagger)
}

/// Just like `on_animation_frame`, except message is the time in milliseconds
/// since the previous frame. So you should get a sequence of values all around
/// `1000 / 60` which is nice for stepping animations by a time delta.
pub fn on_animation_frame_delta(tagger: fn(Float) -> msg) -> Sub(msg) {
  animation_manager.on_animation_frame_delta(tagger)
}

// KEYBOARD

/// Subscribe to key presses that normally produce characters. So you should
/// not rely on this for arrow keys.
///
/// **Note:** Check out [this advice][note] to learn more about decoding key codes.
/// It is more complicated than it should be.
///
/// [note]: https://github.com/elm/browser/blob/1.0.2/notes/keyboard.md
pub fn on_key_press(decoder: Decoder(msg)) -> Sub(msg) {
  on(Document, "keypress", decoder)
}

/// Subscribe to get codes whenever a key goes down. This can be useful for
/// creating games. Maybe you want to know if people are pressing `w`, `a`, `s`,
/// or `d` at any given time.
///
/// **Note:** Check out [this advice][note] to learn more about decoding key codes.
/// It is more complicated than it should be.
///
/// [note]: https://github.com/elm/browser/blob/1.0.2/notes/keyboard.md
pub fn on_key_down(decoder: Decoder(msg)) -> Sub(msg) {
  on(Document, "keydown", decoder)
}

/// Subscribe to get codes whenever a key goes up. Often used in combination
/// with [`on_visibility_change`](#on_visibility_change) to be sure keys do not appear
/// to down and never come back up.
pub fn on_key_up(decoder: Decoder(msg)) -> Sub(msg) {
  on(Document, "keyup", decoder)
}

// MOUSE

/// Subscribe to mouse clicks anywhere on screen. Maybe you need to create a
/// custom drop down. You could listen for clicks when it is open, letting you know
/// if someone clicked out of it:
///
/// ```gleam
/// import elm/browser/events
/// import elm/json/decode
///
/// pub type Msg {
///   ClickOut
/// }
///
/// pub fn subscriptions(model: Model) -> Sub(Msg) {
///   case model.drop_down {
///     Closed(_) -> sub.none()
///     Open(_) -> events.on_click(decode.succeed(ClickOut))
///   }
/// }
/// ```
pub fn on_click(decoder: Decoder(msg)) -> Sub(msg) {
  on(Document, "click", decoder)
}

/// Subscribe to mouse moves anywhere on screen.
///
/// You could use this to implement resizable panels like in Elm's online code
/// editor. Check out the example implementation [here][drag].
///
/// [drag]: https://github.com/elm/browser/blob/1.0.2/examples/src/Drag.elm
///
/// **Note:** Unsubscribe if you do not need these events! Running code on every
/// single mouse movement can be very costly, and it is recommended to only
/// subscribe when absolutely necessary.
pub fn on_mouse_move(decoder: Decoder(msg)) -> Sub(msg) {
  on(Document, "mousemove", decoder)
}

/// Subscribe to get mouse information whenever the mouse button goes down.
pub fn on_mouse_down(decoder: Decoder(msg)) -> Sub(msg) {
  on(Document, "mousedown", decoder)
}

/// Subscribe to get mouse information whenever the mouse button goes up.
/// Often used in combination with [`on_visibility_change`](#on_visibility_change)
/// to be sure keys do not appear to down and never come back up.
pub fn on_mouse_up(decoder: Decoder(msg)) -> Sub(msg) {
  on(Document, "mouseup", decoder)
}

// WINDOW

/// Subscribe to any changes in window size.
///
/// For example, you could track the current width by saying:
///
/// ```gleam
/// import elm/browser/events
///
/// pub type Msg {
///   GotNewWidth(Int)
/// }
///
/// pub fn subscriptions(_model) -> Sub(Msg) {
///   events.on_resize(fn(w, _h) { GotNewWidth(w) })
/// }
/// ```
///
/// **Note:** This is equivalent to getting events from [`window.onresize`][resize].
///
/// [resize]: https://developer.mozilla.org/en-US/docs/Web/API/GlobalEventHandlers/onresize
pub fn on_resize(func: fn(Int, Int) -> msg) -> Sub(msg) {
  on(
    Window,
    "resize",
    decode.field(
      "target",
      decode.map2(
        func,
        decode.field("innerWidth", decode.int()),
        decode.field("innerHeight", decode.int()),
      ),
    ),
  )
}

/// Subscribe to any visibility changes, like if the user switches to a
/// different tab or window. When the user looks away, you may want to:
///
/// - Pause a timer.
/// - Pause an animation.
/// - Pause video or audio.
/// - Pause an image carousel.
/// - Stop polling a server for new information.
/// - Stop waiting for an [`on_key_up`](#on_key_up) event.
pub fn on_visibility_change(func: fn(Visibility) -> msg) -> Sub(msg) {
  let #(hidden, change) = visibility_info()
  on(
    Document,
    change,
    decode.map(
      decode.field("target", decode.field(hidden, decode.bool())),
      with_hidden(func, _),
    ),
  )
}

fn with_hidden(func: fn(Visibility) -> msg, is_hidden: Bool) -> msg {
  func(case is_hidden {
    True -> Hidden
    False -> Visible
  })
}

/// Value describing whether the page is hidden or visible.
pub type Visibility {
  Visible
  Hidden
}

// SUBSCRIPTIONS

type Node {
  Document
  Window
}

fn on(node: Node, name: String, decoder: Decoder(msg)) -> Sub(msg) {
  subscription(MySub(node, name, decoder))
}

type MySub(msg) {
  MySub(Node, String, Decoder(msg))
}

const module_name = "Events"

fn subscription(value: a) -> Sub(msg) {
  platform.leaf_sub(module_name, value)
}

fn sub_map(func: fn(a) -> b, my_sub: MySub(a)) -> MySub(b) {
  let MySub(node, name, decoder) = my_sub
  MySub(node, name, decode.map(decoder, func))
}

// EFFECT MANAGER

type State(msg) {
  State(subs: List(#(String, MySub(msg))), pids: Dict(String, process.Id))
}

fn init() -> Task(Never, State(msg)) {
  task.succeed(State([], dict.new()))
}

pub type Event {
  Event(key: String, event: decode.Value)
}

fn on_self_msg(
  router: platform.Router(msg, Event),
  event: Event,
  state: State(msg),
) -> Task(Never, State(msg)) {
  let Event(key, event_value) = event
  let to_message = fn(sub_key_and_sub) {
    let #(sub_key, MySub(_, _, decoder)) = sub_key_and_sub
    case sub_key == key {
      True -> decode_event(decoder, event_value)
      False -> Error(Nil)
    }
  }
  let messages = list.filter_map(state.subs, to_message)
  task.sequence(list.map(messages, platform.send_to_app(router, _)))
  |> task.and_then(fn(_) { task.succeed(state) })
}

fn on_effects(
  router: platform.Router(msg, Event),
  subs: List(MySub(msg)),
  state: State(msg),
) -> Task(Never, State(msg)) {
  let new_subs = list.map(subs, add_key)
  let new_subs_dict = dict.from_list(new_subs)

  let step_left = fn(_key, pid, acc) {
    let #(deads, lives, news) = acc
    #([pid, ..deads], lives, news)
  }

  let step_both = fn(key, pid, _sub, acc) {
    let #(deads, lives, news) = acc
    #(deads, dict.insert(lives, key, pid), news)
  }

  let step_right = fn(key, sub, acc) {
    let #(deads, lives, news) = acc
    #(deads, lives, [spawn(router, key, sub), ..news])
  }

  let #(dead_pids, live_pids, make_new_pids) =
    dict.fold(state.pids, #([], dict.new(), []), fn(acc, key, pid) {
      case dict.get(new_subs_dict, key) {
        Ok(sub) -> step_both(key, pid, sub, acc)
        Error(Nil) -> step_left(key, pid, acc)
      }
    })

  let #(_, _, make_new_pids2) =
    dict.fold(
      new_subs_dict,
      #(dead_pids, live_pids, make_new_pids),
      fn(acc, key, sub) {
        case dict.has_key(state.pids, key) {
          True -> acc
          False -> step_right(key, sub, acc)
        }
      },
    )

  task.sequence(list.map(dead_pids, process.kill))
  |> task.and_then(fn(_) { task.sequence(make_new_pids2) })
  |> task.and_then(fn(pids) {
    task.succeed(State(new_subs, dict.merge(live_pids, dict.from_list(pids))))
  })
}

// TO KEY

fn add_key(my_sub: MySub(msg)) -> #(String, MySub(msg)) {
  let MySub(node, name, _) = my_sub
  #(node_to_key(node) <> name, my_sub)
}

fn node_to_key(node: Node) -> String {
  case node {
    Document -> "d_"
    Window -> "w_"
  }
}

// SPAWN

fn spawn(
  router: platform.Router(msg, Event),
  key: String,
  my_sub: MySub(msg),
) -> Task(Never, #(String, process.Id)) {
  let MySub(node, name, _) = my_sub
  let actual_node = case node {
    Document -> doc()
    Window -> window()
  }
  task.map(
    browser_on(actual_node, name, fn(event) {
      platform.send_to_self(router, Event(key, event))
    }),
    fn(value) { #(key, value) },
  )
}

@external(javascript, "../browser.ffi.mjs", "_Browser_visibilityInfo")
fn visibility_info() -> #(String, String)

@external(javascript, "../browser.ffi.mjs", "_Browser_decodeEvent")
fn decode_event(
  decoder: Decoder(msg),
  event: decode.Value,
) -> Result(msg, error)

@external(javascript, "../browser.ffi.mjs", "_Browser_on")
fn browser_on(
  node: Dynamic,
  event_name: String,
  send_to_self: fn(decode.Value) -> Task(Never, Nil),
) -> Task(x, process.Id)

@external(javascript, "../browser.ffi.mjs", "_Browser_getDoc")
fn doc() -> Dynamic

@external(javascript, "../browser.ffi.mjs", "_Browser_getWindow")
fn window() -> Dynamic

/// This is needed if you use keyboard, mouse or window listeners.
pub fn event_effect_manager() -> platform.EffectManager {
  platform.create_effect_manager(
    module_name,
    init(),
    on_effects,
    on_self_msg,
    platform.OnlySub(sub_map),
  )
}

/// This is needed if you use animation frame subscriptions.
pub fn animation_effect_manager() -> platform.EffectManager {
  animation_manager.effect_manager()
}
