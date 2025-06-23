import elm/json/decode.{type Decoder}
import elm/json/encode
import elm/platform/cmd.{type Cmd}
import elm/platform/sub.{type Sub}

pub type Program(flags, model, msg)

// TASKS and PROCESSES

// TODO: Opposite order of type params to match Gleam Result?

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

type RawManager

pub opaque type Manager {
  Manager(home: String, raw_manager: RawManager)
}

pub opaque type OutgoingPort(a) {
  OutgoingPort(home: String, raw_manager: RawManager)
}

pub opaque type IncomingPort(a) {
  IncomingPort(home: String, raw_manager: RawManager)
}

/// In Elm, this function is called implicitly by defining the parameters of this function as top-level
/// values in an `effect module`.
/// In Gleam, we need to call it ourselves instead.
@external(javascript, "./platform.ffi.mjs", "_Platform_createManager")
fn create_manager_raw(
  // TODO: Type annotations?
  init: a,
  on_effects: b,
  on_self_msg: c,
  cmd_map: d,
  sub_map: e,
) -> RawManager

pub fn create_manager(
  home: String,
  init: a,
  on_effects: b,
  on_self_msg: c,
  cmd_map: d,
  sub_map: e,
) -> Manager {
  Manager(
    home,
    create_manager_raw(init, on_effects, on_self_msg, cmd_map, sub_map),
  )
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
fn outgoing_port_raw(name: String, encoder: fn(a) -> encode.Value) -> RawManager

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
///         platform.outgoing_port("myPortName", encodeSomeType)
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
  OutgoingPort(name, outgoing_port_raw(name, encoder))
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
pub fn outgoing_port_to_effect_manager(port: fn() -> OutgoingPort(a)) -> Manager {
  case port() {
    OutgoingPort(home, raw_manager) -> Manager(home, raw_manager)
  }
}

@external(javascript, "./platform.ffi.mjs", "_Platform_incomingPort")
fn incoming_port_raw(name: String, decoder: Decoder(a)) -> RawManager

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
///         platform.incoming_port("myPortName", decodeSomeType)
///     }
///
///     // Call:
///     platform.call_incoming_port(port_my_port_name, SomeMsgConstructor)
///
///     // Setup:
///     platform.incoming_port_to_effect_manager(port_my_port_name)
pub fn incoming_port(name: String, decoder: Decoder(a)) -> IncomingPort(a) {
  IncomingPort(name, incoming_port_raw(name, decoder))
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
pub fn incoming_port_to_effect_manager(port: fn() -> IncomingPort(a)) -> Manager {
  case port() {
    IncomingPort(home, raw_manager) -> Manager(home, raw_manager)
  }
}
