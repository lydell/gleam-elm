import elm/basics.{type Never}
import elm/platform
import elm/platform/sub.{type Sub}
import elm/process
import elm/task.{type Task}
import elm/time
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}

// PUBLIC STUFF

/// Subscribe to animation frames. The time passed to your `msg` tagger will
/// be the time of the animation frame.
///
/// This subscription is very useful for smooth animations. You get a message
/// whenever the browser is ready to do some more work on your animation.
pub fn on_animation_frame(tagger: fn(time.Posix) -> msg) -> Sub(msg) {
  subscription(Time(tagger))
}

/// Subscribe to animation frames, but get the time between frames as a `Float`.
/// This can be useful if you want to compute how much movement there should
/// be in a given animation step.
///
/// This subscription is very useful for smooth animations. You get a message
/// whenever the browser is ready to do some more work on your animation.
pub fn on_animation_frame_delta(tagger: fn(Float) -> msg) -> Sub(msg) {
  subscription(Delta(tagger))
}

// SUBSCRIPTIONS

type MySub(msg) {
  Time(fn(time.Posix) -> msg)
  Delta(fn(Float) -> msg)
}

const module_name = "AnimationManager"

fn subscription(value: a) -> Sub(msg) {
  platform.leaf_sub(module_name, value)
}

fn sub_map(func: fn(a) -> b, sub: MySub(a)) -> MySub(b) {
  case sub {
    Time(tagger) -> Time(fn(posix) { func(tagger(posix)) })
    Delta(tagger) -> Delta(fn(delta) { func(tagger(delta)) })
  }
}

// EFFECT MANAGER

type State(msg) {
  State(subs: List(MySub(msg)), request: Option(process.Id), old_time: Int)
}

fn init() -> Task(Never, State(msg)) {
  task.succeed(State([], None, 0))
}

fn on_effects(
  router: platform.Router(msg, Int),
  subs: List(MySub(msg)),
  state: State(msg),
) -> Task(Never, State(msg)) {
  let State(_, request, old_time) = state
  case request, subs {
    None, [] -> init()
    Some(pid), [] -> {
      process.kill(pid)
      |> task.and_then(fn(_) { init() })
    }
    None, _ -> {
      process.spawn(task.and_then(raf(), platform.send_to_self(router, _)))
      |> task.and_then(fn(pid) {
        now()
        |> task.and_then(fn(time) { task.succeed(State(subs, Some(pid), time)) })
      })
    }
    Some(_), _ -> task.succeed(State(subs, request, old_time))
  }
}

fn on_self_msg(
  router: platform.Router(msg, Int),
  new_time: Int,
  state: State(msg),
) -> Task(Never, State(msg)) {
  let State(subs, _, old_time) = state
  let send = fn(sub) {
    case sub {
      Time(tagger) ->
        platform.send_to_app(router, tagger(time.millis_to_posix(new_time)))
      Delta(tagger) ->
        platform.send_to_app(router, tagger(int.to_float(new_time - old_time)))
    }
  }
  process.spawn(task.and_then(raf(), platform.send_to_self(router, _)))
  |> task.and_then(fn(pid) {
    task.sequence(list.map(subs, send))
    |> task.and_then(fn(_) { task.succeed(State(subs, Some(pid), new_time)) })
  })
}

@external(javascript, "../browser.ffi.mjs", "_Browser_rAF")
fn raf() -> Task(x, Int)

@external(javascript, "../browser.ffi.mjs", "_Browser_now")
fn now() -> Task(x, Int)

/// This is needed if you use animation frame subscriptions.
pub fn effect_manager() -> platform.EffectManager {
  platform.create_effect_manager(
    module_name,
    init(),
    on_effects,
    on_self_msg,
    platform.OnlySub(sub_map),
  )
}
