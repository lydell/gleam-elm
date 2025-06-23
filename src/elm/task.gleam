//// Tasks make it easy to describe asynchronous operations that may fail, like
//// HTTP requests or writing to a database.
//// 
//// # Tasks
//// @docs Task, perform, attempt
//// 
//// # Chains
//// @docs andThen, succeed, fail, sequence
//// 
//// # Maps
//// @docs map, map2, map3, map4, map5
//// 
//// # Errors
//// @docs onError, mapError

import elm/basics.{type Never}
import elm/platform
import elm/platform/cmd.{type Cmd}
import gleam/list

/// Here are some common tasks:
/// 
/// - [`now : Task x Posix`][now]
/// - [`focus : String -> Task Error ()`][focus]
/// - [`sleep : Float -> Task x ()`][sleep]
/// 
/// [now]: /packages/elm/time/latest/Time#now
/// [focus]: /packages/elm/browser/latest/Browser-Dom#focus
/// [sleep]: /packages/elm/core/latest/Process#sleep
/// 
/// In each case we have a `Task` that will resolve successfully with an `a` value
/// or unsuccessfully with an `x` value. So `Browser.Dom.focus` we may fail with an
/// `Error` if the given ID does not exist. Whereas `Time.now` never fails so
/// I cannot be more specific than `x`. No such value will ever exist! Instead it
/// always succeeds with the current POSIX time.
/// 
/// More generally a task is a _description_ of what you need to do. Like a todo
/// list. Or like a grocery list. Or like GitHub issues. So saying "the task is
/// to tell me the current POSIX time" does not complete the task! You need
/// [`perform`](#perform) tasks or [`attempt`](#attempt) tasks.
pub type Task(x, a) =
  platform.Task(x, a)

// BASICS

/// A task that succeeds immediately when run. It is usually used with
/// [`andThen`](#andThen). You can use it like `map` if you want:
/// 
///     import Time -- elm install elm/time
/// 
///     timeInMillis : Task x Int
///     timeInMillis =
///       Time.now
///         |> andThen (\t -> succeed (Time.posixToMillis t))
/// 
@external(javascript, "./scheduler.ffi.mjs", "_Scheduler_succeed")
pub fn succeed(value: a) -> Task(x, a)

/// A task that fails immediately when run. Like with `succeed`, this can be
/// used with `andThen` to check on the outcome of another task.
/// 
///     type Error = NotFound
/// 
///     notFound : Task Error a
///     notFound =
///       fail NotFound
@external(javascript, "./scheduler.ffi.mjs", "_Scheduler_fail")
pub fn fail(error: x) -> Task(x, a)

// MAPPING

/// Transform a task. Maybe you want to use [`elm/time`][time] to figure
/// out what time it will be in one hour:
/// 
///     import Task exposing (Task)
///     import Time -- elm install elm/time
/// 
///     timeInOneHour : Task x Time.Posix
///     timeInOneHour =
///       Task.map addAnHour Time.now
/// 
///     addAnHour : Time.Posix -> Time.Posix
///     addAnHour time =
///       Time.millisToPosix (Time.posixToMillis time + 60 * 60 * 1000)
/// 
/// [time]: /packages/elm/time/latest/
pub fn map(task_a: Task(x, a), func: fn(a) -> b) -> Task(x, b) {
  task_a
  |> and_then(fn(a) { succeed(func(a)) })
}

/// Put the results of two tasks together. For example, if we wanted to know
/// the current month, we could use [`elm/time`][time] to ask:
/// 
///     import Task exposing (Task)
///     import Time -- elm install elm/time
/// 
///     getMonth : Task x Int
///     getMonth =
///       Task.map2 Time.toMonth Time.here Time.now
/// 
/// **Note:** Say we were doing HTTP requests instead. `map2` does each task in
/// order, so it would try the first request and only continue after it succeeds.
/// If it fails, the whole thing fails!
/// 
/// [time]: /packages/elm/time/latest/
pub fn map2(
  func: fn(a, b) -> result,
  task_a: Task(x, a),
  task_b: Task(x, b),
) -> Task(x, result) {
  task_a
  |> and_then(fn(a) {
    task_b
    |> and_then(fn(b) { succeed(func(a, b)) })
  })
}

// TODO: map3, map4, map5

/// Start with a list of tasks, and turn them into a single task that returns a
/// list. The tasks will be run in order one-by-one and if any task fails the whole
/// sequence fails.
/// 
///     sequence [ succeed 1, succeed 2 ] == succeed [ 1, 2 ]
pub fn sequence(tasks: List(Task(x, a))) -> Task(x, List(a)) {
  list.fold(tasks, succeed([]), fn(acc, task) {
    map2(fn(value, values) { [value, ..values] }, task, acc)
  })
}

// CHAINING

/// Chain together a task and a callback. The first task will run, and if it is
/// successful, you give the result to the callback resulting in another task. This
/// task then gets run. We could use this to make a task that resolves an hour from
/// now:
/// 
///     import Time -- elm install elm/time
///     import Process
/// 
///     timeInOneHour : Task x Time.Posix
///     timeInOneHour =
///       Process.sleep (60 * 60 * 1000)
///         |> andThen (\_ -> Time.now)
/// 
/// First the process sleeps for an hour **and then** it tells us what time it is.
pub fn and_then(task: Task(x, a), f: fn(a) -> Task(x, b)) -> Task(x, b) {
  and_then_raw(f, task)
}

@external(javascript, "./Scheduler.ffi.mjs", "_Scheduler_andThen")
pub fn and_then_raw(f: fn(a) -> Task(x, b), task: Task(x, a)) -> Task(x, b)

// ERRORS

/// Recover from a failure in a task. If the given task fails, we use the
/// callback to recover.
/// 
///     fail "file not found"
///       |> onError (\msg -> succeed 42)
///       -- succeed 42
/// 
///     succeed 9
///       |> onError (\msg -> succeed 42)
///       -- succeed 9
pub fn on_error(task: Task(x, a), f: fn(x) -> Task(y, a)) -> Task(y, a) {
  on_error_raw(f, task)
}

@external(javascript, "./scheduler.ffi.mjs", "_Scheduler_onError")
pub fn on_error_raw(f: fn(x) -> Task(y, a), task: Task(x, a)) -> Task(y, a)

/// Transform the error value. This can be useful if you need a bunch of error
/// types to match up.
/// 
///     type Error
///       = Http Http.Error
///       | WebGL WebGL.Error
/// 
///     getResources : Task Error Resource
///     getResources =
///       sequence
///         [ mapError Http serverTask
///         , mapError WebGL textureTask
///         ]
pub fn map_error(task: Task(x, a), convert: fn(x) -> y) -> Task(y, a) {
  task |> on_error(fn(error) { fail(convert(error)) })
}

// COMMANDS

type MyCmd(msg) {
  Perform(Task(Never, msg))
}

const module_name = "Task"

fn command(value: a) -> Cmd(msg) {
  platform.leaf_cmd(module_name, value)
}

/// Like I was saying in the [`Task`](#Task) documentation, just having a
/// `Task` does not mean it is done. We must command Elm to `perform` the task:
/// 
///     import Time  -- elm install elm/time
///     import Task
/// 
///     type Msg
///       = Click
///       | Search String
///       | NewTime Time.Posix
/// 
///     getNewTime : Cmd Msg
///     getNewTime =
///       Task.perform NewTime Time.now
/// 
/// If you have worked through [`guide.elm-lang.org`][guide] (highly recommended!)
/// you will recognize `Cmd` from the section on The Elm Architecture. So we have
/// changed a task like "make delicious lasagna" into a command like "Hey Elm, make
/// delicious lasagna and give it to my `update` function as a `Msg` value."
/// 
/// [guide]: https://guide.elm-lang.org/
pub fn perform(to_message: fn(a) -> msg, task: Task(Never, a)) -> Cmd(msg) {
  command(Perform(map(task, to_message)))
}

/// This is very similar to [`perform`](#perform) except it can handle failures!
/// So we could _attempt_ to focus on a certain DOM node like this:
/// 
///     import Browser.Dom  -- elm install elm/browser
///     import Task
/// 
///     type Msg
///       = Click
///       | Search String
///       | Focus (Result Browser.DomError ())
/// 
///     focus : Cmd Msg
///     focus =
///       Task.attempt Focus (Browser.Dom.focus "my-app-search-box")
/// 
/// So the task is "focus on this DOM node" and we are turning it into the command
/// "Hey Elm, attempt to focus on this DOM node and give me a `Msg` about whether
/// you succeeded or failed."
/// 
/// **Note:** Definitely work through [`guide.elm-lang.org`][guide] to get a
/// feeling for how commands fit into The Elm Architecture.
/// 
/// [guide]: https://guide.elm-lang.org/
pub fn attempt(
  result_to_message: fn(Result(a, x)) -> msg,
  task: Task(x, a),
) -> Cmd(msg) {
  command(Perform(
    task
    |> and_then(fn(value) { succeed(result_to_message(Ok(value))) })
    |> on_error(fn(value) { succeed(result_to_message(Error(value))) }),
  ))
}

fn cmd_map(tagger: fn(a) -> b, my_cmd: MyCmd(a)) -> MyCmd(b) {
  case my_cmd {
    Perform(task) -> Perform(map(task, tagger))
  }
}

// MANAGER

fn init() -> Task(Never, Nil) {
  succeed(Nil)
}

fn on_effects(
  router: platform.Router(msg, Never),
  commands: List(MyCmd(msg)),
  _: Nil,
) -> Task(Never, Nil) {
  map(sequence(list.map(commands, spawn_cmd(router, _))), fn(_) { Nil })
}

fn on_self_msg(
  _: platform.Router(msg, Never),
  _: Never,
  _: Nil,
) -> Task(Never, Nil) {
  succeed(Nil)
}

fn spawn_cmd(
  router: platform.Router(msg, Never),
  my_cmd: MyCmd(msg),
) -> Task(Never, Nil) {
  case my_cmd {
    Perform(task) ->
      spawn(
        task
        |> and_then(platform.send_to_app(router, _)),
      )
  }
}

@external(javascript, "./scheduler.ffi.mjs", "_Scheduler_spawn")
fn spawn(task: Task(x, a)) -> Task(x, a)

pub fn manager() -> platform.Manager {
  platform.create_manager(
    module_name,
    init(),
    on_effects,
    on_self_msg,
    platform.OnlyCmd(cmd_map),
  )
}
