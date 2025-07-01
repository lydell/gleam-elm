import elm/basics.{type Never}
import elm/debugger/history.{type History}
import elm/debugger/overlay
import elm/platform/cmd.{type Cmd}
import elm/platform/sub.{type Sub}
import elm/task.{type Task}

// SUBSCRIPTIONS

pub fn wrap_subs(
  subscriptions: fn(model) -> Sub(msg),
) -> fn(Model(model, msg)) -> Sub(Msg(msg)) {
  fn(model: Model(model, msg)) {
    sub.map(subscriptions(get_latest_model(model.state)), UserMsg)
  }
}

// MODEL

pub type Model(model, msg) {
  Model(
    history: History(model, msg),
    state: State(model, msg),
    // expando_model: Expando,
    // expando_msg: Expando,
    popout: Popout,
    layout: Layout,
  )
}

pub type Popout {
  Popout(Popout)
}

pub type Layout {
  Vertical(DragStatus, Float, Float)
  Horizontal(DragStatus, Float, Float)
}

pub type DragStatus {
  Static
  Moving
}

pub fn get_user_model(model: Model(model, msg)) -> model {
  get_current_model(model.state)
}

// STATE

pub type State(model, msg) {
  Running(model)
  Paused(Int, model, model, msg, History(model, msg))
}

/// TODO: Only make public to ffi, not to end users.
pub fn to_blocker_type(model: Model(model, msg)) -> overlay.BlockerType {
  overlay.to_blocker_type(is_paused(model.state))
}

fn get_latest_model(state: State(model, msg)) -> model {
  case state {
    Running(model) -> model
    Paused(_, _, model, _, _) -> model
  }
}

fn get_current_model(state: State(model, msg)) -> model {
  case state {
    Running(model) -> model
    Paused(_, model, _, _, _) -> model
  }
}

fn is_paused(state: State(model, msg)) -> Bool {
  case state {
    Running(_) -> False
    Paused(_, _, _, _, _) -> True
  }
}

fn cached_history(model: Model(model, msg)) -> History(model, msg) {
  case model.state {
    Running(_) -> model.history
    Paused(_, _, _, _, history) -> history
  }
}

// INIT

pub fn wrap_init(
  popout: Popout,
  init: fn(flags) -> #(model, Cmd(msg)),
) -> fn(flags) -> #(Model(model, msg), Cmd(Msg(msg))) {
  fn(flags) {
    let #(user_model, user_commands) = init(flags)
    #(
      Model(
        history: history.empty(user_model),
        state: Running(user_model),
        // expandoModel: Expando.init(user_model),
        // expandoMsg: Expando.init(),
        popout: popout,
        layout: Horizontal(Static, 0.3, 0.5),
      ),
      cmd.map(user_commands, UserMsg),
    )
  }
}

// UPDATE

pub type Msg(msg) {
  NoOp
  UserMsg(msg)
  // | TweakExpandoMsg Expando.Msg
  // | TweakExpandoModel Expando.Msg
  // | Resume
  // | Jump Int
  // | SliderJump Int
  // | Open
  // | Up
  // | Down
  // | Import
  // | Export
  // | Upload String
  // | OverlayMsg Overlay.Msg
  // --
  // | SwapLayout
  // | DragStart
  // | Drag DragInfo
  // | DragEnd
}

type UserUpdate(model, msg) =
  fn(msg, model) -> #(model, Cmd(msg))

pub fn wrap_update(
  update: UserUpdate(model, msg),
) -> fn(Msg(msg), Model(model, msg)) -> #(Model(model, msg), Cmd(Msg(msg))) {
  fn(msg: Msg(msg), model: Model(model, msg)) {
    case msg {
      NoOp -> #(model, cmd.none())
      UserMsg(user_msg) -> {
        let user_model = get_latest_model(model.state)
        let new_history = history.add(user_msg, user_model, model.history)
        let #(new_user_model, user_cmds) = update(user_msg, user_model)
        let commands = cmd.map(user_cmds, UserMsg)
        case model.state {
          Running(_) -> #(
            Model(
              ..model,
              history: new_history,
              state: Running(new_user_model),
              // , expandoModel: Expando.merge new_user_model model.expandoModel
            // , expandoMsg: Expando.merge user_msg model.expandoMsg
            ),
            cmd.batch([commands, scroll(model.popout)]),
          )

          Paused(index, index_model, _, _, history) -> #(
            Model(
              ..model,
              history: new_history,
              state: Paused(
                index,
                index_model,
                new_user_model,
                user_msg,
                history,
              ),
            ),
            commands,
          )
        }
      }
    }
  }
}

// COMMANDS

fn scroll(popout: Popout) -> Cmd(Msg(msg)) {
  task.perform(fn(_) { NoOp }, scroll_raw(popout))
}

@external(javascript, "../debugger.ffi.mjs", "_Debugger_scroll")
fn scroll_raw(popout: Popout) -> Task(Never, Nil)
