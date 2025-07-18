//// # Programs
//// @docs Program, worker
////
//// # Platform Internals
////
//// ## Tasks and Processes
//// @docs Task, ProcessId
////
//// ## Effect Manager Helpers
////
//// An extremely tiny portion of library authors should ever write effect managers.
//// Fundamentally, Elm needs maybe 10 of them total. I get that people are smart,
//// curious, etc. but that is not a substitute for a legitimate reason to make an
//// effect manager. Do you have an *organic need* this fills? Or are you just
//// curious? Public discussions of your explorations should be framed accordingly.
////
//// @docs Router, sendToApp, sendToSelf

import elm/basics.{type Never}
import elm/json/decode.{type Decoder}
import elm/json/encode
import elm/platform/cmd.{type Cmd}
import elm/platform/sub.{type Sub}

// PROGRAMS

/// A `Program` describes an Elm program! How does it react to input? Does it
/// show anything on screen? Etc.
pub type Program(flags, model, msg) =
  fn(Args) -> App(flags, model, msg)

/// Initializing a `Program` takes a configuration object (that is sometimes optional)
/// where you can provide flags and a DOM node (depending on the program type).
pub type Args

/// An `App` is a an object that might have a `ports` property with all ports you
/// have registered effect managers for.
pub type App(flags, model, msg)

/// Create a [headless][] program with no user interface.
///
/// This is great if you want to use Elm as the &ldquo;brain&rdquo; for something
/// else. For example, you could send messages out ports to modify the DOM, but do
/// all the complex logic in Elm.
///
/// [headless]: https://en.wikipedia.org/wiki/Headless_software
///
/// Initializing a headless program from JavaScript looks like this:
///
/// ```javascript
/// var app = Elm.MyThing.init();
/// ```
///
/// If you _do_ want to control the user interface in Elm, the [`Browser`][browser]
/// module has a few ways to create that kind of `Program` instead!
///
/// [headless]: https://en.wikipedia.org/wiki/Headless_software
/// [browser]: /packages/elm/browser/latest/Browser
@external(javascript, "./platform.ffi.mjs", "_Platform_worker")
pub fn worker(
  flags_decoder flags_decoder: Decoder(flags),
  init init: fn(flags) -> #(model, Cmd(msg)),
  update update: fn(msg, model) -> #(model, Cmd(msg)),
  subscriptions subscriptions: fn(model) -> Sub(msg),
  effect_managers effect_managers: List(EffectManager),
) -> Program(flags, model, msg)

// TASKS and PROCESSES

/// Head over to the documentation for the [`Task`](Task) module for more
/// information on this. It is only defined here because it is a platform
/// primitive.
pub type Task(err, ok)

/// Head over to the documentation for the [`Process`](Process) module for
/// information on this. It is only defined here because it is a platform
/// primitive.
pub type ProcessId

// EFFECT MANAGER INTERNALS

/// An effect manager has access to a “router” that routes messages between
/// the main app and your individual effect manager.
pub type Router(app_msg, self_msg)

/// Send the router a message for the main loop of your app. This message will
/// be handled by the overall `update` function, just like events from `Html`.
@external(javascript, "./platform.ffi.mjs", "_Platform_sendToApp")
pub fn send_to_app(router: Router(msg, a), msg: msg) -> Task(x, Nil)

/// Send the router a message for your effect manager. This message will
/// be routed to the `onSelfMsg` function, where you can update the state of your
/// effect manager as necessary.
///
/// As an example, the effect manager for web sockets
@external(javascript, "./platform.ffi.mjs", "_Platform_sendToSelf")
pub fn send_to_self(router: Router(a, msg), msg: msg) -> Task(x, Nil)

type RawEffectManager

pub opaque type EffectManager {
  EffectManager(home: String, raw_effect_manager: RawEffectManager)
}

pub opaque type OutgoingPort(a) {
  OutgoingPort(home: String, raw_effect_manager: RawEffectManager)
}

pub opaque type IncomingPort(a) {
  IncomingPort(home: String, raw_effect_manager: RawEffectManager)
}

/// In Elm, this function is called implicitly by defining the parameters of this function as top-level
/// values in an `effect module`.
/// In Gleam, we need to call it ourselves instead.
@external(javascript, "./platform.ffi.mjs", "_Platform_createManager")
fn create_manager(
  init: Task(Never, state),
  on_effects: fn(Router(app_msg, self_msg), List(bag), state) ->
    Task(Never, state),
  on_self_msg: fn(Router(app_msg, self_msg), self_msg, state) ->
    Task(Never, state),
  cmd_map: cmd_map,
  sub_map: sub_map,
) -> RawEffectManager

pub type BagMap(cmd_a, cmd_b, cmd_a_, cmd_b_, sub_a, sub_b, sub_a_, sub_b_) {
  OnlyCmd(cmd_map: fn(fn(cmd_a) -> cmd_b, cmd_a_) -> cmd_b_)
  OnlySub(sub_map: fn(fn(sub_a) -> sub_b, sub_a_) -> sub_b_)
  BothCmdAndSub(
    cmd_map: fn(fn(cmd_a) -> cmd_b, cmd_a_) -> cmd_b_,
    sub_map: fn(fn(sub_a) -> sub_b, sub_a_) -> sub_b_,
  )
}

pub fn create_effect_manager(
  home: String,
  init: Task(Never, state),
  on_effects: fn(Router(app_msg, self_msg), List(bag), state) ->
    Task(Never, state),
  on_self_msg: fn(Router(app_msg, self_msg), self_msg, state) ->
    Task(Never, state),
  bag_map: BagMap(cmd_a, cmd_b, cmd_a_, cmd_b_, sub_a, sub_b, sub_a_, sub_b_),
) -> EffectManager {
  let effect_manager_raw = case bag_map {
    OnlyCmd(cmd_map) ->
      create_manager(init, on_effects, on_self_msg, cmd_map, 0)
    OnlySub(sub_map) ->
      create_manager(init, on_effects, on_self_msg, 0, sub_map)
    BothCmdAndSub(cmd_map, sub_map) ->
      create_manager(init, on_effects, on_self_msg, cmd_map, sub_map)
  }
  EffectManager(home, effect_manager_raw)
}

/// In Elm, effect modules define `command = MyCmd` at the top, which then automatically defines
/// a function that takes `MyCmd` and returns a `Cmd msg`. The `command` function is defined as
/// `_Platform_leaf('NameOfTheEffectModule')`. Same thing for `subscription = MySub`.
@external(javascript, "./platform.ffi.mjs", "_Platform_leaf")
pub fn leaf_cmd(home: String, value: a) -> Cmd(msg)

/// Like `leaf_cmd` but for `subscription = MySub`.
@external(javascript, "./platform.ffi.mjs", "_Platform_leaf")
pub fn leaf_sub(home: String, value: a) -> Sub(msg)

@external(javascript, "./platform.ffi.mjs", "_Platform_outgoingPort")
fn outgoing_port_raw(encoder: fn(a) -> encode.Value) -> RawEffectManager

/// Defines an outgoing port.
///
/// Elm:
///
///     -- Definition:
///     port myPortName : SomeType -> Cmd msg
///
///     -- Call:
///     myPortName value
///
///     -- Setup: automatic/implicit
///
/// Gleam:
///
///     // Definition:
///     fn port_my_port_name() {
///         platform.outgoing_port("myPortName", encode_some_type)
///     }
///
///     // Call:
///     platform.call_outgoing_port(port_my_port_name, value)
///
///     // Setup:
///     platform.outgoing_port_to_effect_manager(port_my_port_name)
pub fn outgoing_port(
  name: String,
  encoder: fn(a) -> encode.Value,
) -> OutgoingPort(a) {
  OutgoingPort(name, outgoing_port_raw(encoder))
}

/// Call an outgoing port. In Elm, this would just be a regular function call.
/// In Gleam, you need this helper function to do it. See `outgoing_port` for
/// more details.
pub fn call_outgoing_port(port: fn() -> OutgoingPort(a), value: a) -> Cmd(msg) {
  case port() {
    OutgoingPort(home, _) -> leaf_cmd(home, value)
  }
}

/// A port is powered by an effect manager. You need to pass the effect manager
/// when initializing the app. This function extracts the effect manager from a port.
/// See `outgoing_port` for more details.
pub fn outgoing_port_to_effect_manager(
  port: fn() -> OutgoingPort(a),
) -> EffectManager {
  case port() {
    OutgoingPort(home, raw_effect_manager) ->
      EffectManager(home, raw_effect_manager)
  }
}

@external(javascript, "./platform.ffi.mjs", "_Platform_incomingPort")
fn incoming_port_raw(decoder: Decoder(a)) -> RawEffectManager

/// Defines an incoming port.
///
/// Elm:
///
///     -- Definition:
///     port myPortName : (SomeType -> msg) -> Sub msg
///
///     -- Subscribe:
///     myPortName SomeMsgConstructor
///
///     -- Setup: automatic/implicit
///
/// Gleam:
///
///     // Definition:
///     fn port_my_port_name() {
///         platform.incoming_port("myPortName", decode_some_type)
///     }
///
///     // Subscribe:
///     platform.subscribe_incoming_port(port_my_port_name, SomeMsgConstructor)
///
///     // Setup:
///     platform.incoming_port_to_effect_manager(port_my_port_name)
pub fn incoming_port(name: String, decoder: Decoder(a)) -> IncomingPort(a) {
  IncomingPort(name, incoming_port_raw(decoder))
}

/// Subscribe to an incoming port. In Elm, this would just be a regular function call.
/// In Gleam, you need this helper function to do it. See `incoming_port` for
/// more details.
pub fn subscribe_incoming_port(
  port: fn() -> IncomingPort(a),
  to_msg: fn(a) -> msg,
) -> Sub(msg) {
  case port() {
    IncomingPort(home, _) -> leaf_sub(home, to_msg)
  }
}

/// A port is powered by an effect manager. You need to pass the effect manager
/// when initializing the app. This function extracts the effect manager from a port.
/// See `incoming_port` for more details.
pub fn incoming_port_to_effect_manager(
  port: fn() -> IncomingPort(a),
) -> EffectManager {
  case port() {
    IncomingPort(home, raw_effect_manager) ->
      EffectManager(home, raw_effect_manager)
  }
}
