import elm/basics.{type Never}
import elm/debugger/expando.{type Expando}
import elm/debugger/history.{type History}
import elm/debugger/overlay
import elm/html.{type Attribute, type Html, button, div, input, node, span, text}
import elm/html/attributes.{max, min, style, type_, value}
import elm/html/events.{on, on_click, on_input, on_mouse_down, on_mouse_up}
import elm/html/lazy.{lazy}
import elm/json/decode
import elm/platform/cmd.{type Cmd}
import elm/platform/sub.{type Sub}
import elm/task.{type Task}
import elm/virtual_dom as v
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result

// CONSTANTS

pub const initial_window_width: Int = 900

pub const initial_window_height: Int = 420

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
    expando_model: Expando,
    expando_msg: Expando,
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

@external(javascript, "../debugger.ffi.mjs", "_Debugger_isOpen")
fn is_open(popout: Popout) -> Bool

@external(javascript, "../debugger.ffi.mjs", "_Debugger_open")
fn open(popout: Popout) -> Task(Never, Nil)

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
        expando_model: expando.init(user_model),
        expando_msg: expando.init(Nil),
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
  TweakExpandoMsg(expando.Msg)
  TweakExpandoModel(expando.Msg)
  Pause
  Resume
  Jump(Int)
  SliderJump(Int)
  Open
  Up
  Down
  // --
  SwapLayout
  DragStart
  Drag(DragInfo)
  DragEnd
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
              expando_model: expando.merge(new_user_model, model.expando_model),
              expando_msg: expando.merge(user_msg, model.expando_msg),
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
      TweakExpandoMsg(e_msg) -> #(
        Model(..model, expando_msg: expando.update(e_msg, model.expando_msg)),
        cmd.none(),
      )
      TweakExpandoModel(e_msg) -> #(
        Model(
          ..model,
          expando_model: expando.update(e_msg, model.expando_model),
        ),
        cmd.none(),
      )
      Pause ->
        case model.state {
          Running(_) -> {
            let size = history.size(model.history)
            case size == 0 {
              True -> #(model, cmd.none())
              False -> #(jump_update(update, size - 1, model), cmd.none())
            }
          }
          Paused(_, _, _, _, _) -> #(model, cmd.none())
        }
      Resume ->
        case model.state {
          Running(_) -> #(model, cmd.none())

          Paused(_, _, user_model, user_msg, _) -> #(
            Model(
              ..model,
              state: Running(user_model),
              expando_msg: expando.merge(user_msg, model.expando_msg),
              expando_model: expando.merge(user_model, model.expando_model),
            ),
            scroll(model.popout),
          )
        }
      Jump(index) -> #(jump_update(update, index, model), cmd.none())
      SliderJump(index) -> #(
        jump_update(update, index, model),
        scroll_to(history.id_for_message_index(index), model.popout),
      )
      Open -> {
        #(model, task.perform(fn(_) { NoOp }, open(model.popout)))
      }
      Up ->
        case model.state {
          Running(_) -> #(model, cmd.none())
          Paused(i, _, _, _, history) -> {
            let target_index = i + 1
            case target_index < history.size(history) {
              True -> wrap_update(update)(SliderJump(target_index), model)
              False -> wrap_update(update)(Resume, model)
            }
          }
        }
      Down ->
        case model.state {
          Running(_) ->
            wrap_update(update)(Jump(history.size(model.history) - 1), model)
          Paused(index, _, _, _, _) ->
            case index > 0 {
              True -> wrap_update(update)(SliderJump(index - 1), model)
              False -> #(model, cmd.none())
            }
        }
      SwapLayout -> #(
        Model(..model, layout: swap_layout(model.layout)),
        cmd.none(),
      )
      DragStart -> #(
        Model(..model, layout: set_drag_status(Moving, model.layout)),
        cmd.none(),
      )
      Drag(info) -> #(
        Model(..model, layout: drag(info, model.layout)),
        cmd.none(),
      )
      DragEnd -> #(
        Model(..model, layout: set_drag_status(Static, model.layout)),
        cmd.none(),
      )
    }
  }
}

fn jump_update(
  update: UserUpdate(model, msg),
  index: Int,
  model: Model(model, msg),
) -> Model(model, msg) {
  let history = cached_history(model)
  let current_msg = history.get_recent_msg(history)
  let current_model = get_latest_model(model.state)
  let #(index_model, index_msg) = history.get(update, index, history)
  Model(
    ..model,
    state: Paused(index, index_model, current_model, current_msg, history),
    expando_model: expando.merge(index_model, model.expando_model),
    expando_msg: expando.merge(index_msg, model.expando_msg),
  )
}

// LAYOUT HELPERS

fn swap_layout(layout: Layout) -> Layout {
  case layout {
    Horizontal(s, x, y) -> Vertical(s, x, y)
    Vertical(s, x, y) -> Horizontal(s, x, y)
  }
}

fn set_drag_status(status: DragStatus, layout: Layout) -> Layout {
  case layout {
    Horizontal(_, x, y) -> Horizontal(status, x, y)
    Vertical(_, x, y) -> Vertical(status, x, y)
  }
}

fn drag(info: DragInfo, layout: Layout) -> Layout {
  case layout {
    Horizontal(status, _, y) -> Horizontal(status, info.x /. info.width, y)
    Vertical(status, x, _) -> Vertical(status, x, info.y /. info.height)
  }
}

// COMMANDS

fn scroll(popout: Popout) -> Cmd(Msg(msg)) {
  task.perform(fn(_) { NoOp }, scroll_raw(popout))
}

@external(javascript, "../debugger.ffi.mjs", "_Debugger_scroll")
fn scroll_raw(popout: Popout) -> Task(Never, Nil)

fn scroll_to(id: String, popout: Popout) -> Cmd(Msg(msg)) {
  // This is supposed to be:
  // task.perform(fn(_) { NoOp }, scroll_to_raw(id, popout))
  // But to avoid depending on the task manager, we just do the side effect straight away instead.
  scroll_to_raw(id, popout)
  cmd.none()
}

@external(javascript, "../debugger.ffi.mjs", "_Debugger_scrollTo")
fn scroll_to_raw(id: String, popout: Popout) -> Nil

// CORNER VIEW

pub fn corner_view(model: Model(model, msg)) -> Html(Msg(msg)) {
  overlay.view(
    overlay.Config(resume: Resume, open: Open),
    is_paused(model.state),
    is_open(model.popout),
    history.size(model.history),
  )
}

pub fn to_blocker_type(model: Model(model, msg)) -> overlay.BlockerType {
  overlay.to_blocker_type(is_paused(model.state))
}

// BIG DEBUG VIEW

pub fn popout_view(model: Model(model, msg)) -> Html(Msg(msg)) {
  let maybe_index = case model.state {
    Running(_) -> None
    Paused(index, _, _, _, _) -> Some(index)
  }

  let history_to_render = cached_history(model)
  node(
    "body",
    list.append(to_drag_listeners(model.layout), [
      style("margin", "0"),
      style("padding", "0"),
      style("width", "100%"),
      style("height", "100%"),
      style("font-family", "monospace"),
      style("display", "flex"),
      style("background-color", "white"),
      style("flex-direction", to_flex_direction(model.layout)),
    ]),
    [
      view_history(maybe_index, history_to_render, model.layout),
      view_drag_zone(model.layout),
      view_expando(model.expando_msg, model.expando_model, model.layout),
    ],
  )
}

fn to_flex_direction(layout: Layout) -> String {
  case layout {
    Horizontal(_, _, _) -> "row"
    Vertical(_, _, _) -> "column-reverse"
  }
}

// DRAG LISTENERS

fn to_drag_listeners(layout: Layout) -> List(Attribute(Msg(msg))) {
  case get_drag_status(layout) {
    Static -> []
    Moving -> [on_mouse_move(), on_mouse_up(DragEnd)]
  }
}

fn get_drag_status(layout: Layout) -> DragStatus {
  case layout {
    Horizontal(status, _, _) -> status
    Vertical(status, _, _) -> status
  }
}

pub type DragInfo {
  DragInfo(x: Float, y: Float, down: Bool, width: Float, height: Float)
}

fn on_mouse_move() -> Attribute(Msg(msg)) {
  on(
    "mousemove",
    decode.map5(
      fn(x, y, down, width, height) {
        Drag(DragInfo(x, y, down, width, height))
      },
      decode.field("pageX", decode.float()),
      decode.field("pageY", decode.float()),
      decode.field("buttons", decode.map(decode.int(), fn(v) { v == 1 })),
      decode_dimension("innerWidth"),
      decode_dimension("innerHeight"),
    ),
  )
}

fn decode_dimension(field: String) -> decode.Decoder(Float) {
  decode.at(
    ["currentTarget", "ownerDocument", "defaultView", field],
    decode.float(),
  )
}

// VIEW DRAG ZONE

fn view_drag_zone(layout: Layout) -> Html(Msg(msg)) {
  case layout {
    Horizontal(_, x, _) ->
      div(
        [
          style("position", "absolute"),
          style("top", "0"),
          style("left", to_percent(x)),
          style("margin-left", "-5px"),
          style("width", "10px"),
          style("height", "100%"),
          style("cursor", "col-resize"),
          on_mouse_down(DragStart),
        ],
        [],
      )

    Vertical(_, _, y) ->
      div(
        [
          style("position", "absolute"),
          style("top", to_percent(y)),
          style("left", "0"),
          style("margin-top", "-5px"),
          style("width", "100%"),
          style("height", "10px"),
          style("cursor", "row-resize"),
          on_mouse_down(DragStart),
        ],
        [],
      )
  }
}

// LAYOUT HELPERS

fn to_percent(fraction: Float) -> String {
  float.to_string(100.0 *. fraction) <> "%"
}

fn to_mouse_blocker(layout: Layout) -> String {
  case get_drag_status(layout) {
    Static -> "auto"
    Moving -> "none"
  }
}

// VIEW HISTORY

fn view_history(
  maybe_index: option.Option(Int),
  history: History(model, msg),
  layout: Layout,
) -> Html(Msg(msg)) {
  let #(w, h) = to_history_percents(layout)
  let block = to_mouse_blocker(layout)
  div(
    [
      style("width", w),
      style("height", h),
      style("display", "flex"),
      style("flex-direction", "column"),
      style("color", "#DDDDDD"),
      style("background-color", "rgb(61, 61, 61)"),
      style("pointer-events", block),
      style("user-select", block),
    ],
    [
      view_history_slider(history, maybe_index),
      html.map(history.view(maybe_index, history), Jump),
      lazy(view_history_options, layout),
    ],
  )
}

fn to_history_percents(layout: Layout) -> #(String, String) {
  case layout {
    Horizontal(_, x, _) -> #(to_percent(x), "100%")
    Vertical(_, _, y) -> #("100%", to_percent(1.0 -. y))
  }
}

fn view_history_slider(
  history: History(model, msg),
  maybe_index: option.Option(Int),
) -> Html(Msg(msg)) {
  let last_index = history.size(history) - 1
  let selected_index = option.unwrap(maybe_index, last_index)
  div(
    [
      style("display", "flex"),
      style("flex-direction", "row"),
      style("align-items", "center"),
      style("width", "100%"),
      style("height", "36px"),
      style("background-color", "rgb(50, 50, 50)"),
    ],
    [
      lazy(view_play_button, is_playing(maybe_index)),
      input(
        [
          type_("range"),
          style("width", "calc(100% - 56px)"),
          style("height", "36px"),
          style("margin", "0 10px"),
          min("0"),
          max(int.to_string(last_index)),
          value(int.to_string(selected_index)),
          on_input(fn(str) {
            int.parse(str)
            |> result.unwrap(last_index)
            |> SliderJump
          }),
        ],
        [],
      ),
    ],
  )
}

fn view_play_button(playing: Bool) -> Html(Msg(msg)) {
  button(
    [
      style("background", "#1293D8"),
      style("border", "none"),
      style("color", "white"),
      style("cursor", "pointer"),
      style("width", "36px"),
      style("height", "36px"),
      on_click(case playing {
        True -> Pause
        False -> Resume
      }),
    ],
    [
      case playing {
        True -> icon("M2 2h4v12h-4v-12z M10 2h4v12h-4v-12z")
        False -> icon("M2 2l12 7l-12 7z")
      },
    ],
  )
}

fn is_playing(maybe_index: option.Option(Int)) -> Bool {
  case maybe_index {
    None -> True
    Some(_) -> False
  }
}

fn view_history_options(layout: Layout) -> Html(Msg(msg)) {
  div(
    [
      style("width", "100%"),
      style("height", "36px"),
      style("display", "flex"),
      style("flex-direction", "row"),
      style("align-items", "center"),
      style("justify-content", "space-between"),
      style("background-color", "rgb(50, 50, 50)"),
    ],
    [view_history_button("Swap Layout", SwapLayout, to_history_icon(layout))],
  )
}

fn view_history_button(label: String, msg: msg, path: String) -> Html(msg) {
  button(
    [
      style("display", "flex"),
      style("flex-direction", "row"),
      style("align-items", "center"),
      style("background", "none"),
      style("border", "none"),
      style("color", "inherit"),
      style("cursor", "pointer"),
      on_click(msg),
    ],
    [icon(path), span([style("padding-left", "6px")], [text(label)])],
  )
}

fn icon(path: String) -> Html(msg) {
  v.node_ns(
    "http://www.w3.org/2000/svg",
    "svg",
    [
      v.attribute("viewBox", "0 0 16 16"),
      v.attribute("xmlns", "http://www.w3.org/2000/svg"),
      v.attribute("fill", "currentColor"),
      v.attribute("width", "16px"),
      v.attribute("height", "16px"),
    ],
    [
      v.node_ns(
        "http://www.w3.org/2000/svg",
        "path",
        [v.attribute("d", path)],
        [],
      ),
    ],
  )
}

fn to_history_icon(layout: Layout) -> String {
  case layout {
    Horizontal(_, _, _) ->
      "M13 1a3 3 0 0 1 3 3v8a3 3 0 0 1-3 3h-10a3 3 0 0 1-3-3v-8a3 3 0 0 1 3-3z M13 3h-10a1 1 0 0 0-1 1v5h12v-5a1 1 0 0 0-1-1z M14 10h-12v2a1 1 0 0 0 1 1h10a1 1 0 0 0 1-1z"
    Vertical(_, _, _) ->
      "M0 4a3 3 0 0 1 3-3h10a3 3 0 0 1 3 3v8a3 3 0 0 1-3 3h-10a3 3 0 0 1-3-3z M2 4v8a1 1 0 0 0 1 1h2v-10h-2a1 1 0 0 0-1 1z M6 3v10h7a1 1 0 0 0 1-1v-8a1 1 0 0 0-1-1z"
  }
}

// VIEW EXPANDO

fn view_expando(
  expando_msg: Expando,
  expando_model: Expando,
  layout: Layout,
) -> Html(Msg(msg)) {
  let #(w, h) = to_expando_percents(layout)
  let block = to_mouse_blocker(layout)
  div(
    [
      style("display", "block"),
      style("width", "calc(" <> w <> " - 4em)"),
      style("height", "calc(" <> h <> " - 4em)"),
      style("padding", "2em"),
      style("margin", "0"),
      style("overflow", "auto"),
      style("pointer-events", block),
      style("-webkit-user-select", block),
      style("-moz-user-select", block),
      style("-ms-user-select", block),
      style("user-select", block),
    ],
    [
      div([style("color", "#ccc"), style("padding", "0 0 1em 0")], [
        text("-- MESSAGE"),
      ]),
      html.map(expando.view([], expando_msg), TweakExpandoMsg),
      div([style("color", "#ccc"), style("padding", "1em 0")], [
        text("-- MODEL"),
      ]),
      html.map(expando.view([], expando_model), TweakExpandoModel),
    ],
  )
}

fn to_expando_percents(layout: Layout) -> #(String, String) {
  case layout {
    Horizontal(_, x, _) -> #(to_percent(1.0 -. x), "100%")
    Vertical(_, _, y) -> #("100%", to_percent(y))
  }
}
