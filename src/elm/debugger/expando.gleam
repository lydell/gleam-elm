//// Library for viewing Elm values in the debugger.

import elm/html.{type Attribute, type Html, div, span, text}
import elm/html/attributes.{style}
import elm/html/events.{on_click}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, Some}
import gleam/string

// MODEL

pub type Expando {
  S(String)
  Primitive(String)
  Sequence(SeqType, Bool, List(Expando))
  Dictionary(Bool, List(#(Expando, Expando)))
  Record(Bool, Dict(String, Expando))
  Constructor(Option(String), Bool, List(Expando))
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

// INITIALIZE

@external(javascript, "../debugger.ffi.mjs", "_Debugger_init")
fn debugger_init(value: a) -> Expando

pub fn init(value: a) -> Expando {
  init_help(True, debugger_init(value))
}

fn init_help(is_outer: Bool, expando: Expando) -> Expando {
  case expando {
    S(_) -> expando
    Primitive(_) -> expando

    Sequence(seq_type, _, items) ->
      case is_outer {
        True -> Sequence(seq_type, False, list.map(items, init_help(False, _)))
        False ->
          case list.length(items) <= 8 {
            True -> Sequence(seq_type, False, items)
            False -> expando
          }
      }

    Dictionary(_, key_value_pairs) ->
      case is_outer {
        True ->
          Dictionary(
            False,
            list.map(key_value_pairs, fn(pair) {
              let #(k, v) = pair
              #(k, init_help(False, v))
            }),
          )
        False ->
          case list.length(key_value_pairs) <= 8 {
            True -> Dictionary(False, key_value_pairs)
            False -> expando
          }
      }

    Record(_, entries) ->
      case is_outer {
        True ->
          Record(
            False,
            dict.map_values(entries, fn(_, v) { init_help(False, v) }),
          )
        False ->
          case dict.size(entries) <= 4 {
            True -> Record(False, entries)
            False -> expando
          }
      }

    Constructor(maybe_name, _, args) ->
      case is_outer {
        True ->
          Constructor(maybe_name, False, list.map(args, init_help(False, _)))
        False ->
          case list.length(args) <= 4 {
            True -> Constructor(maybe_name, False, args)
            False -> expando
          }
      }
  }
}

// PRESERVE OLD EXPANDO STATE (open/closed)

pub fn merge(value: a, expando: Expando) -> Expando {
  merge_help(expando, debugger_init(value))
}

fn merge_help(old: Expando, new: Expando) -> Expando {
  case old, new {
    _, S(_) -> new
    _, Primitive(_) -> new

    Sequence(_, is_closed, old_values), Sequence(seq_type, _, new_values) ->
      Sequence(seq_type, is_closed, merge_list_help(old_values, new_values))

    Dictionary(is_closed, _), Dictionary(_, key_value_pairs) ->
      Dictionary(is_closed, key_value_pairs)

    Record(is_closed, old_dict), Record(_, new_dict) ->
      Record(
        is_closed,
        dict.map_values(new_dict, fn(k, v) { merge_dict_help(old_dict, k)(v) }),
      )

    Constructor(_, is_closed, old_values),
      Constructor(maybe_name, _, new_values)
    ->
      Constructor(
        maybe_name,
        is_closed,
        merge_list_help(old_values, new_values),
      )

    _, _ -> new
  }
}

fn merge_list_help(olds: List(Expando), news: List(Expando)) -> List(Expando) {
  case olds, news {
    [], _ -> news
    _, [] -> news
    [x, ..xs], [y, ..ys] -> [merge_help(x, y), ..merge_list_help(xs, ys)]
  }
}

fn merge_dict_help(
  old_dict: Dict(String, Expando),
  key: String,
) -> fn(Expando) -> Expando {
  fn(value: Expando) -> Expando {
    case dict.get(old_dict, key) {
      Error(Nil) -> value
      Ok(old_value) -> merge_help(old_value, value)
    }
  }
}

// UPDATE

pub type Msg {
  Toggle
  Index(Redirect, Int, Msg)
  Field(String, Msg)
}

pub type Redirect {
  None
  Key
  Value
}

pub fn update(msg: Msg, value: Expando) -> Expando {
  case value {
    S(_) -> value
    Primitive(_) -> value

    Sequence(seq_type, is_closed, value_list) ->
      case msg {
        Toggle -> Sequence(seq_type, !is_closed, value_list)
        Index(None, index, sub_msg) ->
          Sequence(
            seq_type,
            is_closed,
            update_index(index, update(sub_msg, _), value_list),
          )
        Index(_, _, _) -> value
        Field(_, _) -> value
      }

    Dictionary(is_closed, key_value_pairs) ->
      case msg {
        Toggle -> Dictionary(!is_closed, key_value_pairs)
        Index(redirect, index, sub_msg) ->
          case redirect {
            None -> value
            Key ->
              Dictionary(
                is_closed,
                update_index(
                  index,
                  fn(pair) {
                    let #(k, v) = pair
                    #(update(sub_msg, k), v)
                  },
                  key_value_pairs,
                ),
              )
            Value ->
              Dictionary(
                is_closed,
                update_index(
                  index,
                  fn(pair) {
                    let #(k, v) = pair
                    #(k, update(sub_msg, v))
                  },
                  key_value_pairs,
                ),
              )
          }
        Field(_, _) -> value
      }

    Record(is_closed, value_dict) ->
      case msg {
        Toggle -> Record(!is_closed, value_dict)
        Index(_, _, _) -> value
        Field(field, sub_msg) -> {
          let new_dict = case dict.get(value_dict, field) {
            Ok(existing_value) -> {
              let updated_value = update(sub_msg, existing_value)
              dict.insert(value_dict, field, updated_value)
            }
            Error(_) -> value_dict
          }
          Record(is_closed, new_dict)
        }
      }

    Constructor(maybe_name, is_closed, value_list) ->
      case msg {
        Toggle -> Constructor(maybe_name, !is_closed, value_list)
        Index(None, index, sub_msg) ->
          Constructor(
            maybe_name,
            is_closed,
            update_index(index, update(sub_msg, _), value_list),
          )
        Index(_, _, _) -> value
        Field(_, _) -> value
      }
  }
}

fn update_index(n: Int, func: fn(a) -> a, list: List(a)) -> List(a) {
  case list {
    [] -> []
    [x, ..xs] ->
      case n <= 0 {
        True -> [func(x), ..xs]
        False -> [x, ..update_index(n - 1, func, xs)]
      }
  }
}

// VIEW

pub fn view(maybe_key: Option(String), expando: Expando) -> Html(Msg) {
  case expando {
    S(string_rep) ->
      div(
        left_pad(maybe_key),
        line_starter(maybe_key, option.None, [span([red()], [text(string_rep)])]),
      )

    Primitive(string_rep) ->
      div(
        left_pad(maybe_key),
        line_starter(maybe_key, option.None, [
          span([blue()], [text(string_rep)]),
        ]),
      )

    Sequence(seq_type, is_closed, value_list) ->
      view_sequence(maybe_key, seq_type, is_closed, value_list)

    Dictionary(is_closed, key_value_pairs) ->
      view_dictionary(maybe_key, is_closed, key_value_pairs)

    Record(is_closed, value_dict) ->
      view_record(maybe_key, is_closed, value_dict)

    Constructor(maybe_name, is_closed, value_list) ->
      view_constructor(maybe_key, maybe_name, is_closed, value_list)
  }
}

// VIEW SEQUENCE

fn view_sequence(
  maybe_key: Option(String),
  seq_type: SeqType,
  is_closed: Bool,
  value_list: List(Expando),
) -> Html(Msg) {
  let starter = seq_type_to_string(list.length(value_list), seq_type)
  div(left_pad(maybe_key), [
    div(
      [on_click(Toggle)],
      line_starter(maybe_key, Some(is_closed), [text(starter)]),
    ),
    case is_closed {
      True -> text("")
      False -> view_sequence_open(value_list)
    },
  ])
}

fn view_sequence_open(values: List(Expando)) -> Html(Msg) {
  div([], list.index_map(values, fn(v, i) { view_constructor_entry(i, v) }))
}

// VIEW DICTIONARY

fn view_dictionary(
  maybe_key: Option(String),
  is_closed: Bool,
  key_value_pairs: List(#(Expando, Expando)),
) -> Html(Msg) {
  let starter = "Dict(" <> int.to_string(list.length(key_value_pairs)) <> ")"
  div(left_pad(maybe_key), [
    div(
      [on_click(Toggle)],
      line_starter(maybe_key, Some(is_closed), [text(starter)]),
    ),
    case is_closed {
      True -> text("")
      False -> view_dictionary_open(key_value_pairs)
    },
  ])
}

fn view_dictionary_open(key_value_pairs: List(#(Expando, Expando))) -> Html(Msg) {
  div(
    [],
    list.index_map(key_value_pairs, fn(p, i) { view_dictionary_entry(i, p) }),
  )
}

fn view_dictionary_entry(index: Int, pair: #(Expando, Expando)) -> Html(Msg) {
  let #(key, value) = pair
  case key {
    S(string_rep) ->
      html.map(view(Some(string_rep), value), Index(Value, index, _))
    Primitive(string_rep) ->
      html.map(view(Some(string_rep), value), Index(Value, index, _))
    _ ->
      div([], [
        html.map(view(Some("key"), key), Index(Key, index, _)),
        html.map(view(Some("value"), value), Index(Value, index, _)),
      ])
  }
}

// VIEW RECORD

fn view_record(
  maybe_key: Option(String),
  is_closed: Bool,
  record: Dict(String, Expando),
) -> Html(Msg) {
  let #(start, middle, end) = case is_closed {
    True -> {
      let #(_, tiny_html) = view_tiny_record(record)
      #(tiny_html, text(""), text(""))
    }
    False -> #(
      [text("(")],
      view_record_open(record),
      div(left_pad(Some(Nil)), [text(")")]),
    )
  }

  div(left_pad(maybe_key), [
    div([on_click(Toggle)], line_starter(maybe_key, Some(is_closed), start)),
    middle,
    end,
  ])
}

fn view_record_open(record: Dict(String, Expando)) -> Html(Msg) {
  div([], list.map(dict.to_list(record), view_record_entry))
}

fn view_record_entry(entry: #(String, Expando)) -> Html(Msg) {
  let #(field, value) = entry
  html.map(view(Some(field), value), Field(field, _))
}

// VIEW CONSTRUCTOR

fn view_constructor(
  maybe_key: Option(String),
  maybe_name: Option(String),
  is_closed: Bool,
  value_list: List(Expando),
) -> Html(Msg) {
  let tiny_args =
    list.map(value_list, fn(val) {
      let #(_, html) = view_extra_tiny(val)
      html
    })

  let description = case maybe_name, tiny_args {
    option.None, [] -> [text("()")]
    option.None, [x, ..xs] ->
      list.fold(xs, [text("( "), span([], x)], fn(acc, args) {
        list.append(acc, [text(", "), span([], args)])
      })
      |> list.append([text(" )")])
    option.Some(name), [] -> [text(name)]
    option.Some(name), [x, ..xs] ->
      list.fold(xs, [text(name <> " "), span([], x)], fn(acc, args) {
        list.append(acc, [text(" "), span([], args)])
      })
  }

  let #(maybe_is_closed, open_html) = case value_list {
    [] -> #(option.None, div([], []))
    [entry] ->
      case entry {
        S(_) -> #(option.None, div([], []))
        Primitive(_) -> #(option.None, div([], []))
        Sequence(_, _, sub_value_list) -> #(
          option.Some(is_closed),
          case is_closed {
            True -> div([], [])
            False ->
              html.map(view_sequence_open(sub_value_list), Index(None, 0, _))
          },
        )
        Dictionary(_, key_value_pairs) -> #(
          option.Some(is_closed),
          case is_closed {
            True -> div([], [])
            False ->
              html.map(view_dictionary_open(key_value_pairs), Index(None, 0, _))
          },
        )
        Record(_, record) -> #(option.Some(is_closed), case is_closed {
          True -> div([], [])
          False -> html.map(view_record_open(record), Index(None, 0, _))
        })
        Constructor(_, _, sub_value_list) -> #(
          option.Some(is_closed),
          case is_closed {
            True -> div([], [])
            False ->
              html.map(view_constructor_open(sub_value_list), Index(None, 0, _))
          },
        )
      }
    _ -> #(option.Some(is_closed), case is_closed {
      True -> div([], [])
      False -> view_constructor_open(value_list)
    })
  }

  div(left_pad(maybe_key), [
    div(
      [on_click(Toggle)],
      line_starter(maybe_key, maybe_is_closed, description),
    ),
    open_html,
  ])
}

fn view_constructor_open(value_list: List(Expando)) -> Html(Msg) {
  div([], list.index_map(value_list, fn(v, i) { view_constructor_entry(i, v) }))
}

fn view_constructor_entry(index: Int, value: Expando) -> Html(Msg) {
  html.map(view(Some(int.to_string(index)), value), Index(None, index, _))
}

// VIEW TINY

fn view_tiny(value: Expando) -> #(Int, List(Html(msg))) {
  case value {
    S(string_rep) -> {
      let str = elide_middle(string_rep)
      #(string.length(str), [span([red()], [text(str)])])
    }
    Primitive(string_rep) -> #(string.length(string_rep), [
      span([blue()], [text(string_rep)]),
    ])
    Sequence(seq_type, _, value_list) ->
      view_tiny_help(seq_type_to_string(list.length(value_list), seq_type))
    Dictionary(_, key_value_pairs) ->
      view_tiny_help(
        "Dict(" <> int.to_string(list.length(key_value_pairs)) <> ")",
      )
    Record(_, record) -> view_tiny_record(record)
    Constructor(maybe_name, _, []) ->
      view_tiny_help(option.unwrap(maybe_name, "Unit"))
    Constructor(maybe_name, _, value_list) ->
      view_tiny_help(case maybe_name {
        option.None -> "Tuple(" <> int.to_string(list.length(value_list)) <> ")"
        option.Some(name) -> name <> " …"
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

fn view_tiny_record(record: Dict(String, Expando)) -> #(Int, List(Html(msg))) {
  case dict.is_empty(record) {
    True -> #(2, [text("()")])
    False -> view_tiny_record_help(0, "( ", dict.to_list(record))
  }
}

fn view_tiny_record_help(
  length: Int,
  starter: String,
  entries: List(#(String, Expando)),
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

fn view_extra_tiny(value: Expando) -> #(Int, List(Html(msg))) {
  case value {
    Record(_, record) -> view_extra_tiny_record(0, "(", dict.keys(record))
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
        True -> #(length + 2, [text("…)")])
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

fn line_starter(
  maybe_key: Option(String),
  maybe_is_closed: Option(Bool),
  description: List(Html(msg)),
) -> List(Html(msg)) {
  let arrow = case maybe_is_closed {
    option.None -> make_arrow("")
    option.Some(True) -> make_arrow("▸")
    option.Some(False) -> make_arrow("▾")
  }

  case maybe_key {
    option.None -> [arrow, ..description]
    option.Some(key) -> [
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
    option.None -> []
    option.Some(_) -> [style("padding-left", "4ch")]
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
