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
///     import elm/time
/// 
///     fn time_in_millis() -> Task(x, Int) {
///       time.now()
///       |> and_then(fn(t) { succeed(time.posix_to_millis(t)) })
///     }
/// 
@external(javascript, "./scheduler.ffi.mjs", "_Scheduler_succeed")
pub fn succeed(value: a) -> Task(x, a)

/// A task that fails immediately when run. Like with `succeed`, this can be
/// used with `andThen` to check on the outcome of another task.
/// 
///     type Error {
///       NotFound
///     }
/// 
///     fn not_found() -> Task(Error, a) {
///       fail(NotFound)
///     }
@external(javascript, "./scheduler.ffi.mjs", "_Scheduler_fail")
pub fn fail(error: x) -> Task(x, a)

// MAPPING

/// Transform a task. Maybe you want to use [`elm/time`][time] to figure
/// out what time it will be in one hour:
/// 
///     import elm/task.{type Task}
///     import elm/time
/// 
///     fn time_in_one_hour() -> Task(x, time.Posix) {
///       task.map(time.now(), add_an_hour)
///     }
/// 
///     fn add_an_hour(time: time.Posix) -> time.Posix {
///       time.millis_to_posix(time.posix_to_millis(time) + 60 * 60 * 1000)
///     }
/// 
/// [time]: /packages/elm/time/latest/
pub fn map(task_a: Task(x, a), func: fn(a) -> b) -> Task(x, b) {
  task_a
  |> and_then(fn(a) { succeed(func(a)) })
}

/// Put the results of two tasks together. For example, if we wanted to know
/// the current month, we could use [`elm/time`][time] to ask:
/// 
///     import elm/task.{type Task}
///     import elm/time
/// 
///     fn get_month() -> Task(x, Int) {
///       task.map2(time.to_month, time.here(), time.now())
///     }
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

///
pub fn map3(
  func: fn(a, b, c) -> result,
  task_a: Task(x, a),
  task_b: Task(x, b),
  task_c: Task(x, c),
) -> Task(x, result) {
  task_a
  |> and_then(fn(a) {
    task_b
    |> and_then(fn(b) {
      task_c
      |> and_then(fn(c) { succeed(func(a, b, c)) })
    })
  })
}

///
pub fn map4(
  func: fn(a, b, c, d) -> result,
  task_a: Task(x, a),
  task_b: Task(x, b),
  task_c: Task(x, c),
  task_d: Task(x, d),
) -> Task(x, result) {
  task_a
  |> and_then(fn(a) {
    task_b
    |> and_then(fn(b) {
      task_c
      |> and_then(fn(c) {
        task_d
        |> and_then(fn(d) { succeed(func(a, b, c, d)) })
      })
    })
  })
}

///
pub fn map5(
  func: fn(a, b, c, d, e) -> result,
  task_a: Task(x, a),
  task_b: Task(x, b),
  task_c: Task(x, c),
  task_d: Task(x, d),
  task_e: Task(x, e),
) -> Task(x, result) {
  task_a
  |> and_then(fn(a) {
    task_b
    |> and_then(fn(b) {
      task_c
      |> and_then(fn(c) {
        task_d
        |> and_then(fn(d) {
          task_e
          |> and_then(fn(e) { succeed(func(a, b, c, d, e)) })
        })
      })
    })
  })
}

/// Start with a list of tasks, and turn them into a single task that returns a
/// list. The tasks will be run in order one-by-one and if any task fails the whole
/// sequence fails.
/// 
///     sequence([succeed(1), succeed(2)]) == succeed([1, 2])
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
///     import elm/time
///     import elm/process
/// 
///     fn time_in_one_hour() -> Task(x, time.Posix) {
///       process.sleep(60 * 60 * 1000)
///       |> and_then(fn(_) { time.now() })
///     }
/// 
/// First the process sleeps for an hour **and then** it tells us what time it is.
pub fn and_then(task: Task(x, a), f: fn(a) -> Task(x, b)) -> Task(x, b) {
  and_then_raw(f, task)
}

@external(javascript, "./Scheduler.ffi.mjs", "_Scheduler_andThen")
fn and_then_raw(f: fn(a) -> Task(x, b), task: Task(x, a)) -> Task(x, b)

// ERRORS

/// Recover from a failure in a task. If the given task fails, we use the
/// callback to recover.
/// 
///     fail("file not found")
///     |> on_error(fn(msg) { succeed(42) })
///     // succeed(42)
/// 
///     succeed(9)
///     |> on_error(fn(msg) { succeed(42) })
///     // succeed(9)
pub fn on_error(task: Task(x, a), f: fn(x) -> Task(y, a)) -> Task(y, a) {
  on_error_raw(f, task)
}

@external(javascript, "./scheduler.ffi.mjs", "_Scheduler_onError")
fn on_error_raw(f: fn(x) -> Task(y, a), task: Task(x, a)) -> Task(y, a)

/// Transform the error value. This can be useful if you need a bunch of error
/// types to match up.
/// 
///     type Error {
///       Http(http.Error)
///       WebGL(webgl.Error)
///     }
/// 
///     fn get_resources() -> Task(Error, Resource) {
///       sequence([
///         map_error(server_task, Http),
///         map_error(texture_task, WebGL),
///       ])
///     }
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
///     import elm/time
///     import elm/task
/// 
///     type Msg {
///       Click
///       Search(String)
///       NewTime(time.Posix)
///     }
/// 
///     fn get_new_time() -> Cmd(Msg) {
///       task.perform(NewTime, time.now())
///     }
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
///     import elm/browser/dom
///     import elm/task
/// 
///     type Msg {
///       Click
///       Search(String)
///       Focus(Result(dom.Error, Nil))
///     }
/// 
///     fn focus() -> Cmd(Msg) {
///       task.attempt(Focus, dom.focus("my-app-search-box"))
///     }
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

/// This is needed if you use `task.perform` or `task.attempt`.
/// Many things, for example `browser/navigation`, use `task.perform` internally,
/// so this effect manager is always registered automatically. You don’t need
/// to import and use this value yourself.
pub fn automatically_registered_effect_manager() -> platform.EffectManager {
  platform.create_effect_manager(
    module_name,
    init(),
    on_effects,
    on_self_msg,
    platform.OnlyCmd(cmd_map),
  )
}
