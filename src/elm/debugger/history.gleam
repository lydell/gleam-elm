import elm/array.{type Array}
import elm/html.{type Html}
import elm/html/attributes
import elm/html/events
import elm/html/keyed
import elm/html/lazy
import gleam/int
import gleam/list
import gleam/option.{type Option}

// CONSTANTS

/// NOTE: While the app is running we display (max_snapshot_size * 2) messages
/// in the message panel. We want to keep this number relatively low to reduce
/// the number of DOM nodes the browser have to deal with. However, we want
/// this number to be high to retain as few model snapshots as possible to
/// reduce memory usage.
///
/// 31 is selected because 62 messages fills up the height of a 27 inch monitor,
/// with the current style, while avoiding a tree representation in Elm arrays.
///
/// Performance and memory use seems good.
const max_snapshot_size = 31

// HISTORY

pub type History(model, msg) {
  History(
    snapshots: Array(Snapshot(model, msg)),
    recent: RecentHistory(model, msg),
    num_messages: Int,
  )
}

pub type RecentHistory(model, msg) {
  RecentHistory(model: model, messages: List(msg), num_messages: Int)
}

pub type Snapshot(model, msg) {
  Snapshot(model: model, messages: Array(msg))
}

pub fn empty(model: model) -> History(model, msg) {
  History(
    snapshots: array.empty(),
    recent: RecentHistory(model: model, messages: [], num_messages: 0),
    num_messages: 0,
  )
}

pub fn size(history: History(model, msg)) -> Int {
  history.num_messages
}

pub fn get_initial_model(history: History(model, msg)) -> model {
  case array.get(history.snapshots, 0) {
    Ok(snapshot) -> snapshot.model
    Error(_) -> history.recent.model
  }
}

// ADD MESSAGES

pub fn add(
  msg: msg,
  model: model,
  history: History(model, msg),
) -> History(model, msg) {
  case add_recent(msg, model, history.recent) {
    #(option.Some(snapshot), new_recent) ->
      History(
        snapshots: array.push(history.snapshots, snapshot),
        recent: new_recent,
        num_messages: history.num_messages + 1,
      )
    #(option.None, new_recent) ->
      History(
        snapshots: history.snapshots,
        recent: new_recent,
        num_messages: history.num_messages + 1,
      )
  }
}

fn add_recent(
  msg: msg,
  new_model: model,
  recent: RecentHistory(model, msg),
) -> #(Option(Snapshot(model, msg)), RecentHistory(model, msg)) {
  case recent.num_messages == max_snapshot_size {
    True -> #(
      option.Some(Snapshot(
        model: recent.model,
        messages: array.from_list(recent.messages),
      )),
      RecentHistory(model: new_model, messages: [msg], num_messages: 1),
    )
    False -> #(
      option.None,
      RecentHistory(
        model: recent.model,
        messages: [msg, ..recent.messages],
        num_messages: recent.num_messages + 1,
      ),
    )
  }
}

// GET SUMMARY

pub fn get(
  update: fn(msg, model) -> #(model, a),
  index: Int,
  history: History(model, msg),
) -> #(model, msg) {
  let recent = history.recent
  let snapshot_max = history.num_messages - recent.num_messages

  case index >= snapshot_max {
    True -> {
      let result =
        list.fold(
          recent.messages,
          Stepping(index - snapshot_max, recent.model),
          fn(acc, msg) { get_help(update, msg, acc) },
        )
      undone(result)
    }
    False -> {
      case array.get(history.snapshots, index / max_snapshot_size) {
        Error(_) ->
          // Debug.crash "UI should only let you ask for real indexes!"
          get(update, index, history)
        Ok(snapshot) -> {
          let result =
            array.foldr(
              snapshot.messages,
              Stepping(index % max_snapshot_size, snapshot.model),
              fn(msg, acc) { get_help(update, msg, acc) },
            )
          undone(result)
        }
      }
    }
  }
}

pub fn get_recent_msg(history: History(model, msg)) -> msg {
  case history.recent.messages {
    [] ->
      // Debug.crash "Cannot provide most recent message!"
      get_recent_msg(history)
    [first, ..] -> first
  }
}

type GetResult(model, msg) {
  Stepping(Int, model)
  Done(msg, model)
}

fn get_help(
  update: fn(msg, model) -> #(model, a),
  msg: msg,
  get_result: GetResult(model, msg),
) -> GetResult(model, msg) {
  case get_result {
    Done(_, _) -> get_result
    Stepping(n, model) ->
      case n == 0 {
        True -> {
          let #(new_model, _) = update(msg, model)
          Done(msg, new_model)
        }
        False -> {
          let #(new_model, _) = update(msg, model)
          Stepping(n - 1, new_model)
        }
      }
  }
}

fn undone(get_result: GetResult(model, msg)) -> #(model, msg) {
  case get_result {
    Done(msg, model) -> #(model, msg)
    Stepping(_, _) ->
      // Debug.crash "Bug in History.get"
      undone(get_result)
  }
}

// VIEW

pub fn view(maybe_index: Option(Int), history: History(model, msg)) -> Html(Int) {
  let index = option.unwrap(maybe_index, -1)
  let only_render_recent_messages =
    index != -1 || array.length(history.snapshots) < 2

  let old_stuff = case only_render_recent_messages {
    True -> lazy.lazy3(view_all_snapshots, index, 0, history.snapshots)
    False ->
      lazy.lazy3(
        view_recent_snapshots,
        index,
        history.recent.num_messages,
        history.snapshots,
      )
  }

  let recent_message_start_index =
    history.num_messages - history.recent.num_messages

  let new_stuff = {
    let #(_, keyed_nodes) =
      list.fold(
        history.recent.messages,
        #(recent_message_start_index, []),
        fn(acc, msg) { cons_msg(index, msg, acc) },
      )
    keyed.node("div", [], keyed_nodes)
  }

  let more_button_list = case only_render_recent_messages {
    True -> []
    False -> [show_more_button(history.num_messages)]
  }

  html.div(
    [
      attributes.id("elm-debugger-sidebar"),
      attributes.style("width", "100%"),
      attributes.style("overflow-y", "auto"),
      attributes.style("height", "calc(100% - 72px)"),
    ],
    [styles(), new_stuff, old_stuff, ..more_button_list],
  )
}

// VIEW SNAPSHOTS

fn view_all_snapshots(
  selected_index: Int,
  start_index: Int,
  snapshots: Array(Snapshot(model, msg)),
) -> Html(Int) {
  let #(_, nodes) =
    array.foldl(snapshots, #(start_index, []), fn(snapshot, acc) {
      cons_snapshot(selected_index, snapshot, acc)
    })
  html.div([], nodes)
}

fn view_recent_snapshots(
  selected_index: Int,
  recent_messages_num: Int,
  snapshots: Array(Snapshot(model, msg)),
) -> Html(Int) {
  let array_length = array.length(snapshots)
  let messages_to_fill = max_snapshot_size - recent_messages_num
  let starting_index =
    array_length * max_snapshot_size - max_snapshot_size - messages_to_fill

  let snapshots_to_render = case
    array.get(snapshots, array_length - 2),
    array.get(snapshots, array_length - 1)
  {
    Ok(filler_snapshot), Ok(recent_snapshot) ->
      array.from_list([
        Snapshot(
          model: filler_snapshot.model,
          messages: array.slice(filler_snapshot.messages, 0, messages_to_fill),
        ),
        recent_snapshot,
      ])
    _, _ -> snapshots
  }

  view_all_snapshots(selected_index, starting_index, snapshots_to_render)
}

fn cons_snapshot(
  selected_index: Int,
  snapshot: Snapshot(model, msg),
  acc: #(Int, List(Html(Int))),
) -> #(Int, List(Html(Int))) {
  let #(index, rest) = acc
  let next_index = index + array.length(snapshot.messages)
  let selected_index_help = case
    next_index > selected_index && selected_index >= index
  {
    True -> selected_index
    False -> -1
  }

  #(next_index, [
    lazy.lazy3(view_snapshot, selected_index_help, index, snapshot),
    ..rest
  ])
}

fn view_snapshot(
  selected_index: Int,
  index: Int,
  snapshot: Snapshot(model, msg),
) -> Html(Int) {
  let #(_, keyed_nodes) =
    array.foldr(snapshot.messages, #(index, []), fn(msg, acc) {
      cons_msg(selected_index, msg, acc)
    })
  keyed.node("div", [], keyed_nodes)
}

// VIEW MESSAGE

fn cons_msg(
  current_index: Int,
  msg: msg,
  acc: #(Int, List(#(String, Html(Int)))),
) -> #(Int, List(#(String, Html(Int)))) {
  let #(index, rest) = acc
  #(index + 1, [
    #(int.to_string(index), lazy.lazy3(view_message, current_index, index, msg)),
    ..rest
  ])
}

fn view_message(current_index: Int, index: Int, msg: msg) -> Html(Int) {
  let class_name = case current_index == index {
    True -> "elm-debugger-entry elm-debugger-entry-selected"
    False -> "elm-debugger-entry"
  }

  let message_name = message_to_string(msg)

  html.div(
    [
      attributes.id(id_for_message_index(index)),
      attributes.class(class_name),
      events.on_click(index),
    ],
    [
      html.span(
        [
          attributes.title(message_name),
          attributes.class("elm-debugger-entry-content"),
        ],
        [html.text(message_name)],
      ),
      html.span([attributes.class("elm-debugger-entry-index")], [
        html.text(int.to_string(index)),
      ]),
    ],
  )
}

@external(javascript, "../debugger.ffi.mjs", "messageToString")
fn message_to_string(msg: msg) -> String

fn show_more_button(num_messages: Int) -> Html(Int) {
  let label_text = "View more messages"
  let next_index = num_messages - 1 - max_snapshot_size * 2

  html.div(
    [attributes.class("elm-debugger-entry"), events.on_click(next_index)],
    [
      html.span(
        [
          attributes.title(label_text),
          attributes.class("elm-debugger-entry-content"),
        ],
        [html.text(label_text)],
      ),
      html.span([attributes.class("elm-debugger-entry-index")], []),
    ],
  )
}

pub fn id_for_message_index(index: Int) -> String {
  "msg-" <> int.to_string(index)
}

// STYLES

fn styles() -> Html(msg) {
  html.node("style", [], [
    html.text(
      "
.elm-debugger-entry {
  cursor: pointer;
  width: 100%;
  box-sizing: border-box;
  padding: 8px;
}

.elm-debugger-entry:hover {
  background-color: rgb(41, 41, 41);
}

.elm-debugger-entry-selected, .elm-debugger-entry-selected:hover {
  background-color: rgb(10, 10, 10);
}

.elm-debugger-entry-content {
  width: calc(100% - 40px);
  padding: 0 5px;
  box-sizing: border-box;
  text-overflow: ellipsis;
  white-space: nowrap;
  overflow: hidden;
  display: inline-block;
}

.elm-debugger-entry-index {
  color: #666;
  width: 40px;
  text-align: right;
  display: block;
  float: right;
}
",
    ),
  ])
}
