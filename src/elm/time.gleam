// SUBSCRIPTIONS

import elm/platform
import elm/platform/sub.{type Sub}
import elm/process
import elm/task.{type Task}
import gleam/dict
import gleam/list

/// A computer representation of time. It is the same all over Earth, so if we
/// have a phone call or meeting at a certain POSIX time, there is no ambiguity.
/// 
/// It is very hard for humans to _read_ a POSIX time though, so we use functions
/// like [`toHour`](#toHour) and [`toMinute`](#toMinute) to `view` them.
pub type Posix {
  Posix(Int)
}

/// Get the POSIX time at the moment when this task is run.
pub fn now() -> Task(x, Posix) {
  now_raw(millis_to_posix)
}

@external(javascript, "./time.ffi.mjs", "_Time_now")
pub fn now_raw(millis_to_posix: fn(Int) -> Posix) -> Task(x, Posix)

/// Turn a `Posix` time into the number of milliseconds since 1970 January 1
/// at 00:00:00 UTC. It was a Thursday.
pub fn posix_to_millis(posix: Posix) -> Int {
  let Posix(millis) = posix
  millis
}

/// Turn milliseconds into a `Posix` time.
pub fn millis_to_posix(millis: Int) -> Posix {
  Posix(millis)
}

/// Get the current time periodically. How often though? Well, you provide an
/// interval in milliseconds (like `1000` for a second or `60 * 1000` for a minute
/// or `60 * 60 * 1000` for an hour) and that is how often you get a new time!
/// 
/// Check out [this example](https://elm-lang.org/examples/time) to see how to use
/// it in an application.
/// 
/// **This function is not for animation.** Use the [`onAnimationFrame`][af]
/// function for that sort of thing! It syncs up with repaints and will end up
/// being much smoother for any moving visuals.
/// 
/// [af]: /packages/elm/browser/latest/Browser-Events#onAnimationFrame
pub fn every(interval: Float, tagger: fn(Posix) -> msg) -> Sub(msg) {
  subscription(Every(interval, tagger))
}

type MySub(msg) {
  Every(Float, fn(Posix) -> msg)
}

const module_name = "Time"

fn subscription(value: a) -> Sub(msg) {
  platform.leaf_sub(module_name, value)
}

fn sub_map(f: fn(a) -> b, my_sub: MySub(a)) -> MySub(b) {
  case my_sub {
    Every(interval, tagger) -> Every(interval, fn(value) { f(tagger(value)) })
  }
}

// EFFECT MANAGER

type State(msg) {
  State(taggers: Taggers(msg), processes: Processes)
}

type Processes =
  dict.Dict(Float, platform.ProcessId)

type Taggers(msg) =
  dict.Dict(Float, List(fn(Posix) -> msg))

// TODO: Is there discussion about Never in Gleam?
// Should I define Basics?
pub type Never {
  Never(Never)
}

fn init() -> Task(Never, State(msg)) {
  task.succeed(State(dict.new(), dict.new()))
}

fn on_effects(
  router: platform.Router(msg, Float),
  subs: List(MySub(msg)),
  state: State(msg),
) -> Task(Never, State(msg)) {
  let new_taggers = list.fold(subs, dict.new(), add_my_sub)

  let kill_task =
    dict.fold(state.processes, task.succeed(Nil), fn(acc, interval, process_id) {
      case dict.has_key(new_taggers, interval) {
        True -> acc
        False -> task.and_then(process.kill(process_id), fn(_) { acc })
      }
    })

  let #(spawn_list, existing_dict) =
    dict.fold(new_taggers, #([], dict.new()), fn(acc, interval, _) {
      let #(spawns, existing) = acc
      case dict.get(state.processes, interval) {
        Ok(process_id) -> #(spawns, dict.insert(existing, interval, process_id))
        Error(Nil) -> #([interval, ..spawns], existing)
      }
    })

  kill_task
  |> task.and_then(fn(_) { spawn_help(router, spawn_list, existing_dict) })
  |> task.and_then(fn(new_processes) {
    task.succeed(State(new_taggers, new_processes))
  })
}

fn add_my_sub(state: Taggers(msg), my_sub: MySub(msg)) -> Taggers(msg) {
  case my_sub {
    Every(interval, tagger) ->
      case dict.get(state, interval) {
        Error(Nil) -> dict.insert(state, interval, [tagger])
        Ok(taggers) -> dict.insert(state, interval, [tagger, ..taggers])
      }
  }
}

fn spawn_help(
  router: platform.Router(msg, Float),
  intervals: List(Float),
  processes: Processes,
) -> Task(x, Processes) {
  case intervals {
    [] -> task.succeed(processes)

    [interval, ..rest] -> {
      let spawn_timer =
        process.spawn(set_interval(
          interval,
          platform.send_to_self(router, interval),
        ))

      let spawn_rest = fn(id) {
        spawn_help(router, rest, dict.insert(processes, interval, id))
      }
      spawn_timer
      |> task.and_then(spawn_rest)
    }
  }
}

fn on_self_msg(
  router: platform.Router(msg, Float),
  interval: Float,
  state: State(msg),
) -> Task(Never, State(msg)) {
  case dict.get(state.taggers, interval) {
    Error(Nil) -> task.succeed(state)

    Ok(taggers) -> {
      let tell_taggers = fn(time) {
        task.sequence(
          list.map(taggers, fn(tagger) {
            platform.send_to_app(router, tagger(time))
          }),
        )
      }
      now()
      |> task.and_then(tell_taggers)
      |> task.and_then(fn(_) { task.succeed(state) })
    }
  }
}

@external(javascript, "./time.ffi.mjs", "_Time_setInterval")
fn set_interval(duration: Float, task: Task(Never, Nil)) -> Task(x, Never)

pub fn manager() -> platform.Manager {
  platform.create_manager(
    module_name,
    init(),
    on_effects,
    on_self_msg,
    0,
    sub_map,
  )
}
