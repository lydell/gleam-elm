import elm/html.{type Attribute, type Html, div, span, text}
import elm/html/attributes.{style}
import elm/html/events.{on_click}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/set.{type Set}
import gleam/string

// MODEL

pub type Expando {
  Expando(
    unexpanded: Unexpanded,
    expanded: Set(Path),
    view_more: Dict(Path, Int),
  )
}

pub type Path =
  List(String)

pub type Unexpanded {
  Unexpanded
}

pub type Expanded {
  S(String)
  Primitive(String)
  Sequence(SeqType, List(Unexpanded))
  Dictionary(List(#(Unexpanded, Unexpanded)))
  Record(Dict(String, Unexpanded))
  Constructor(Option(String), List(Unexpanded))
}

pub type SeqType {
  ListSeq
  SetSeq
  ArraySeq
}

fn seq_type_to_string(n: Int, seq_type: SeqType) -> String {
  case seq_type {
    ListSeq -> "List(" <> int.to_string(n) <> ")"
    SetSeq -> "Set(" <> int.to_string(n) <> ")"
    ArraySeq -> "Array(" <> int.to_string(n) <> ")"
  }
}

fn maximum_items_to_view(path: Path, expando: Expando) -> Int {
  // Show 100 items at a time.
  case dict.get(expando.view_more, path) {
    Ok(count) -> count * 100
    Error(_) -> 100
  }
}

// INITIALIZE

@external(javascript, "../debugger.ffi.mjs", "_Debugger_toUnexpanded")
fn to_unexpanded(value: a) -> Unexpanded

@external(javascript, "../debugger.ffi.mjs", "_Debugger_init")
fn debugger_init(value: Unexpanded) -> Expanded

pub fn init(value: a) -> Expando {
  Expando(
    unexpanded: to_unexpanded(value),
    expanded: set.from_list([[]]),
    view_more: dict.new(),
  )
}

// PRESERVE OLD EXPANDO STATE (open/closed)

pub fn merge(value: a, expando: Expando) -> Expando {
  Expando(..expando, unexpanded: to_unexpanded(value))
}

// UPDATE

pub type Msg {
  Toggle(Path)
  ViewMore(Path)
}

pub fn update(msg: Msg, expando: Expando) -> Expando {
  case msg {
    Toggle(path) -> {
      let new_expanded = case set.contains(expando.expanded, path) {
        True -> set.delete(expando.expanded, path)
        False -> set.insert(expando.expanded, path)
      }
      Expando(..expando, expanded: new_expanded)
    }
    ViewMore(path) -> {
      let new_view_more =
        dict.upsert(expando.view_more, path, fn(maybe_count) {
          case maybe_count {
            Some(count) -> count + 1
            None -> 2
          }
        })
      Expando(..expando, view_more: new_view_more)
    }
  }
}

// VIEW

pub fn view(path: Path, expando: Expando) -> Html(Msg) {
  let maybe_key = list_first(path)
  case debugger_init(expando.unexpanded) {
    S(string_rep) ->
      div(
        left_pad(maybe_key),
        line_starter(maybe_key, None, [span([red()], [text(string_rep)])]),
      )

    Primitive(string_rep) ->
      div(
        left_pad(maybe_key),
        line_starter(maybe_key, None, [span([blue()], [text(string_rep)])]),
      )

    Sequence(seq_type, value_list) ->
      view_sequence(path, seq_type, expando, value_list)

    Dictionary(key_value_pairs) ->
      view_dictionary(path, expando, key_value_pairs)

    Record(value_dict) -> view_record(path, expando, value_dict)

    Constructor(maybe_name, value_list) ->
      view_constructor(path, maybe_name, expando, value_list)
  }
}

// VIEW SEQUENCE

fn view_sequence(
  path: Path,
  seq_type: SeqType,
  expando: Expando,
  value_list: List(Unexpanded),
) -> Html(Msg) {
  let starter = seq_type_to_string(list.length(value_list), seq_type)
  let maybe_key = list_first(path)
  let is_closed = !set.contains(expando.expanded, path)

  div(left_pad(maybe_key), [
    div(
      [on_click(Toggle(path))],
      line_starter(maybe_key, Some(is_closed), [text(starter)]),
    ),
    case is_closed {
      True -> text("")
      False -> view_sequence_open(path, expando, value_list)
    },
  ])
}

fn view_sequence_open(
  path: Path,
  expando: Expando,
  values: List(Unexpanded),
) -> Html(Msg) {
  let max = maximum_items_to_view(path, expando)
  div([], view_sequence_open_help(path, expando, 0, max, values, []))
}

fn view_sequence_open_help(
  path: Path,
  expando: Expando,
  index: Int,
  max: Int,
  values: List(Unexpanded),
  acc: List(Html(Msg)),
) -> List(Html(Msg)) {
  case index < max {
    True ->
      case values {
        [] -> list.reverse(acc)
        [value, ..rest] ->
          view_sequence_open_help(path, expando, index + 1, max, rest, [
            view_constructor_entry(path, expando, index, value),
            ..acc
          ])
      }
    False -> list.reverse([view_more_button(path), ..acc])
  }
}

// VIEW DICTIONARY

fn view_dictionary(
  path: Path,
  expando: Expando,
  key_value_pairs: List(#(Unexpanded, Unexpanded)),
) -> Html(Msg) {
  let starter = "Dict(" <> int.to_string(list.length(key_value_pairs)) <> ")"
  let maybe_key = list_first(path)
  let is_closed = !set.contains(expando.expanded, path)

  div(left_pad(maybe_key), [
    div(
      [on_click(Toggle(path))],
      line_starter(maybe_key, Some(is_closed), [text(starter)]),
    ),
    case is_closed {
      True -> text("")
      False -> view_dictionary_open(path, expando, key_value_pairs)
    },
  ])
}

fn view_dictionary_open(
  path: Path,
  expando: Expando,
  key_value_pairs: List(#(Unexpanded, Unexpanded)),
) -> Html(Msg) {
  let max = maximum_items_to_view(path, expando)
  div([], view_dictionary_open_help(path, expando, 0, max, key_value_pairs, []))
}

fn view_dictionary_open_help(
  path: Path,
  expando: Expando,
  index: Int,
  max: Int,
  key_value_pairs: List(#(Unexpanded, Unexpanded)),
  acc: List(Html(Msg)),
) -> List(Html(Msg)) {
  case index < max {
    True ->
      case key_value_pairs {
        [] -> list.reverse(acc)
        [key_value, ..rest] ->
          view_dictionary_open_help(path, expando, index + 1, max, rest, [
            view_dictionary_entry(
              [int.to_string(index), ..path],
              expando,
              key_value,
            ),
            ..acc
          ])
      }
    False -> list.reverse([view_more_button(path), ..acc])
  }
}

fn view_dictionary_entry(
  path: Path,
  expando: Expando,
  key_value: #(Unexpanded, Unexpanded),
) -> Html(Msg) {
  let #(key, value) = key_value
  case debugger_init(key) {
    S(string_rep) ->
      view([string_rep, ..path], Expando(..expando, unexpanded: value))
    Primitive(string_rep) ->
      view([string_rep, ..path], Expando(..expando, unexpanded: value))
    _ ->
      div([], [
        view(["key", ..path], Expando(..expando, unexpanded: key)),
        view(["value", ..path], Expando(..expando, unexpanded: value)),
      ])
  }
}

// VIEW RECORD

/// Note: This function is never reached in Gleam. A `Record` is always
/// a single child of a `Constructor`. `view_constructor` renders that by itself.
fn view_record(
  path: Path,
  expando: Expando,
  record: Dict(String, Unexpanded),
) -> Html(Msg) {
  let maybe_key = list_first(path)
  let is_closed = !set.contains(expando.expanded, path)

  let #(start, middle, end) = case is_closed {
    True -> {
      let #(_, tiny_html) = view_tiny_record(record)
      #(tiny_html, text(""), text(""))
    }
    False -> #(
      [text("{")],
      view_record_open(path, expando, record),
      div(left_pad(Some(Nil)), [text("}")]),
    )
  }

  div(left_pad(maybe_key), [
    div(
      [on_click(Toggle(path))],
      line_starter(maybe_key, Some(is_closed), start),
    ),
    middle,
    end,
  ])
}

fn view_record_open(
  path: Path,
  expando: Expando,
  record: Dict(String, Unexpanded),
) -> Html(Msg) {
  div(
    [],
    list.map(record_to_sorted_list(record), view_record_entry(path, expando, _)),
  )
}

fn view_record_entry(
  path: Path,
  expando: Expando,
  entry: #(String, Unexpanded),
) -> Html(Msg) {
  let #(field, value) = entry
  view([field, ..path], Expando(..expando, unexpanded: value))
}

fn record_to_sorted_list(
  record: Dict(String, Unexpanded),
) -> List(#(String, Unexpanded)) {
  record
  |> dict.to_list
  |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
}

// VIEW CONSTRUCTOR

fn view_constructor(
  path: Path,
  maybe_name: Option(String),
  expando: Expando,
  value_list: List(Unexpanded),
) -> Html(Msg) {
  let maybe_key = list_first(path)
  let is_closed = !set.contains(expando.expanded, path)

  let tiny_args =
    list.map(value_list, fn(val) {
      let #(_, html) = view_extra_tiny(val)
      html
    })

  let description = case maybe_name, tiny_args {
    None, [] -> [text("#()")]
    None, [x, ..xs] ->
      list.fold(xs, [text("#("), span([], x)], fn(acc, args) {
        list.append(acc, [text(", "), span([], args)])
      })
      |> list.append([text(")")])
    Some(name), [] -> [text(name)]
    Some(name), [x, ..xs] ->
      list.append(
        list.fold(xs, [text(name <> "("), span([], x)], fn(acc, args) {
          list.append(acc, [text(", "), span([], args)])
        }),
        [text(")")],
      )
  }

  let #(maybe_is_closed, open_html) = case value_list {
    [] -> #(None, div([], []))
    [entry] ->
      case debugger_init(entry) {
        S(_) -> #(None, div([], []))
        Primitive(_) -> #(None, div([], []))
        Sequence(_, sub_value_list) -> #(Some(is_closed), case is_closed {
          True -> div([], [])
          False -> view_sequence_open(["0", ..path], expando, sub_value_list)
        })
        Dictionary(key_value_pairs) -> #(Some(is_closed), case is_closed {
          True -> div([], [])
          False -> view_dictionary_open(["0", ..path], expando, key_value_pairs)
        })
        Record(record) -> #(Some(is_closed), case is_closed {
          True -> div([], [])
          False -> view_record_open(["0", ..path], expando, record)
        })
        Constructor(_, sub_value_list) -> #(Some(is_closed), case is_closed {
          True -> div([], [])
          False -> view_constructor_open(["0", ..path], expando, sub_value_list)
        })
      }
    _ -> #(Some(is_closed), case is_closed {
      True -> div([], [])
      False -> view_constructor_open(["0", ..path], expando, value_list)
    })
  }

  div(left_pad(maybe_key), [
    div(
      [on_click(Toggle(path))],
      line_starter(maybe_key, maybe_is_closed, description),
    ),
    open_html,
  ])
}

fn view_constructor_open(
  path: Path,
  expando: Expando,
  value_list: List(Unexpanded),
) -> Html(Msg) {
  div(
    [],
    list.index_map(value_list, fn(value, index) {
      view_constructor_entry(path, expando, index, value)
    }),
  )
}

fn view_constructor_entry(
  path: Path,
  expando: Expando,
  index: Int,
  value: Unexpanded,
) -> Html(Msg) {
  view([int.to_string(index), ..path], Expando(..expando, unexpanded: value))
}

// VIEW TINY

fn view_tiny(value: Unexpanded) -> #(Int, List(Html(msg))) {
  case debugger_init(value) {
    S(string_rep) -> {
      let str = elide_middle(string_rep)
      #(string.length(str), [span([red()], [text(str)])])
    }
    Primitive(string_rep) -> #(string.length(string_rep), [
      span([blue()], [text(string_rep)]),
    ])
    Sequence(seq_type, value_list) ->
      view_tiny_help(seq_type_to_string(list.length(value_list), seq_type))
    Dictionary(key_value_pairs) ->
      view_tiny_help(
        "Dict(" <> int.to_string(list.length(key_value_pairs)) <> ")",
      )
    Record(record) -> view_tiny_record(record)
    Constructor(maybe_name, []) ->
      view_tiny_help(option.unwrap(maybe_name, "#()"))
    Constructor(maybe_name, value_list) ->
      view_tiny_help(case maybe_name {
        None -> "Tuple(" <> int.to_string(list.length(value_list)) <> ")"
        Some(name) -> name <> "(…)"
      })
  }
}

fn view_tiny_help(str: String) -> #(Int, List(Html(msg))) {
  #(string.length(str), [text(str)])
}

fn elide_middle(str: String) -> String {
  case string.length(str) <= 18 {
    True -> str
    False -> string.slice(str, 0, 8) <> "..." <> string.slice(str, -8, 8)
  }
}

// VIEW TINY RECORDS

fn view_tiny_record(record: Dict(String, Unexpanded)) -> #(Int, List(Html(msg))) {
  case dict.is_empty(record) {
    True -> #(2, [text("()")])
    False -> view_tiny_record_help(0, "( ", record_to_sorted_list(record))
  }
}

fn view_tiny_record_help(
  length: Int,
  starter: String,
  entries: List(#(String, Unexpanded)),
) -> #(Int, List(Html(msg))) {
  case entries {
    [] -> #(length + 2, [text(" )")])
    [#(field, value), ..rest] -> {
      let field_len = string.length(field)
      let #(value_len, value_htmls) = view_extra_tiny(value)
      let new_length = length + field_len + value_len + 5

      case new_length > 60 {
        True -> #(length + 4, [text(", … )")])
        False -> {
          let #(final_length, other_htmls) =
            view_tiny_record_help(new_length, ", ", rest)
          #(final_length, [
            text(starter),
            span([purple()], [text(field)]),
            text(": "),
            span([], value_htmls),
            ..other_htmls
          ])
        }
      }
    }
  }
}

fn view_extra_tiny(value: Unexpanded) -> #(Int, List(Html(msg))) {
  case debugger_init(value) {
    Record(record) ->
      view_extra_tiny_record(
        0,
        "",
        list.map(record_to_sorted_list(record), fn(a) { a.0 }),
      )
    _ -> view_tiny(value)
  }
}

fn view_extra_tiny_record(
  length: Int,
  starter: String,
  entries: List(String),
) -> #(Int, List(Html(msg))) {
  case entries {
    [] -> #(length + 1, [text(")")])
    [field, ..rest] -> {
      let next_length = length + string.length(field) + 1
      case next_length > 18 {
        True -> #(length + 1, [text("…")])
        False -> {
          let #(final_length, other_htmls) =
            view_extra_tiny_record(next_length, ",", rest)
          #(final_length, [
            text(starter),
            span([purple()], [text(field)]),
            ..other_htmls
          ])
        }
      }
    }
  }
}

// VIEW HELPERS

fn view_more_button(path: Path) -> Html(Msg) {
  div(left_pad(list_first(path)), [
    div([on_click(ViewMore(path)), ..left_pad(Some(Nil))], [text("View more")]),
  ])
}

fn line_starter(
  maybe_key: Option(String),
  maybe_is_closed: Option(Bool),
  description: List(Html(msg)),
) -> List(Html(msg)) {
  let arrow = case maybe_is_closed {
    None -> make_arrow("")
    Some(True) -> make_arrow("▸")
    Some(False) -> make_arrow("▾")
  }

  case maybe_key {
    None -> [arrow, ..description]
    Some(key) -> [
      arrow,
      span([purple()], [text(key)]),
      text(": "),
      ..description
    ]
  }
}

fn make_arrow(arrow: String) -> Html(msg) {
  span(
    [
      style("color", "#777"),
      style("padding-left", "2ch"),
      style("width", "2ch"),
      style("display", "inline-block"),
    ],
    [text(arrow)],
  )
}

fn left_pad(maybe_key: Option(a)) -> List(Attribute(msg)) {
  case maybe_key {
    None -> []
    Some(_) -> [style("padding-left", "4ch")]
  }
}

fn red() -> Attribute(msg) {
  style("color", "rgb(196, 26, 22)")
}

fn blue() -> Attribute(msg) {
  style("color", "rgb(28, 0, 207)")
}

fn purple() -> Attribute(msg) {
  style("color", "rgb(136, 19, 145)")
}

fn list_first(list: List(a)) -> Option(a) {
  case list.first(list) {
    Ok(item) -> Some(item)
    Error(_) -> None
  }
}
