//// > **Note:** Elm has **managed effects**, meaning that things like HTTP
//// > requests or writing to disk are all treated as *data* in Elm. When this
//// > data is given to the Elm runtime system, it can do some “query optimization”
//// > before actually performing the effect. Perhaps unexpectedly, this managed
//// > effects idea is the heart of why Elm is so nice for testing, reuse,
//// > reproducibility, etc.
//// >
//// > Elm has two kinds of managed effects: commands and subscriptions.
////

// COMMANDS

/// A command is a way of telling Elm, “Hey, I want you to do this thing!”
/// So if you want to send an HTTP request, you would need to command Elm to do it.
/// Or if you wanted to ask for geolocation, you would need to command Elm to go
/// get it.
///
/// Every `Cmd` specifies (1) which effects you need access to and (2) the type of
/// messages that will come back into your application.
///
/// **Note:** Do not worry if this seems confusing at first! As with every Elm user
/// ever, commands will make more sense as you work through [the Elm Architecture
/// Tutorial](https://guide.elm-lang.org/architecture/) and see how they
/// fit into a real application!
pub type Cmd(msg)

/// Tell the runtime that there are no commands.
pub fn none() -> Cmd(msg) {
  batch([])
}

/// When you need the runtime system to perform a couple commands, you
/// can batch them together. Each is handed to the runtime at the same time,
/// and since each can perform arbitrary operations in the world, there are
/// no ordering guarantees about the results.
///
/// **Note:** `Cmd.none` and `Cmd.batch [ Cmd.none, Cmd.none ]` and `Cmd.batch []`
/// all do the same thing.
@external(javascript, "../platform.ffi.mjs", "_Platform_batch")
pub fn batch(cmds: List(Cmd(msg))) -> Cmd(msg)

// FANCY STUFF

/// Transform the messages produced by a command.
/// Very similar to [`Html.map`](/packages/elm/html/latest/Html#map).
///
/// This is very rarely useful in well-structured Elm code, so definitely read the
/// section on [structure][] in the guide before reaching for this!
///
/// [structure]: https://guide.elm-lang.org/webapps/structure.html
@external(javascript, "../platform.ffi.mjs", "_Platform_map")
pub fn map(cmd: Cmd(a), tagger: fn(a) -> msg) -> Cmd(msg)
