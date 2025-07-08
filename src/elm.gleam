import elm/array
import elm/debugger
import elm/html
import elm/html/events
import elm/json/decode
import elm/json/encode
import elm/platform
import elm/platform/cmd
import elm/platform/sub
import elm/time
import gleam/dict
import gleam/int
import gleam/set

fn view(model: Model) {
  html.div([], [
    html.text("Hello Elm Camp!"),
    html.button([events.on_click(IncrementPressed(Thing(foo: 5, bar: "yes")))], [
      html.text(int.to_string(model.counter)),
    ]),
    html.div([], [html.text(int.to_string(model.time_counter))]),
  ])
}

pub type Model {
  Model(
    counter: Int,
    time_counter: Int,
    // The rest are just for testing the Debugger view.
    tuple0: #(),
    tuple1: #(Int),
    tuple2: #(Int, Float),
    tuple3: #(Int, Float, String),
    tuple4: #(#(), Nil, Float, String),
    list: List(Int),
    array: array.Array(Int),
    set: set.Set(Int),
    dict: dict.Dict(String, Int),
    nil: Nil,
    html: html.Html(String),
    custom: Custom,
    record: Wrapper,
  )
}

pub type Custom {
  Custom(Int)
}

pub type Wrapper {
  Wrapper(Record, Int)
}

pub type Record {
  Record(one: Int, two: String)
}

fn init(_) -> #(Model, cmd.Cmd(Msg)) {
  #(
    Model(
      counter: 0,
      time_counter: 0,
      tuple0: #(),
      tuple1: #(1),
      tuple2: #(5, 2.3),
      tuple3: #(5, 2.3, "str"),
      tuple4: #(#(), Nil, 2.3, "str"),
      list: [1, 2, 3],
      array: array.from_list([1, 2, 3]),
      set: set.from_list([1, 2, 3]),
      dict: dict.from_list([#("one", 1), #("two", 2)]),
      nil: Nil,
      html: html.div([], []),
      custom: Custom(1),
      record: Wrapper(Record(1, "two"), 0),
    ),
    cmd.none(),
  )
}

pub type Msg {
  IncrementPressed(Thing)
  TimePassed(time.Posix)
}

pub type Thing {
  Thing(foo: Int, bar: String)
}

fn window_alert() {
  platform.outgoing_port("windowAlert", encode.string)
}

fn update(msg: Msg, model: Model) -> #(Model, cmd.Cmd(Msg)) {
  case msg {
    IncrementPressed(_) -> #(
      Model(..model, counter: model.counter + 1),
      platform.call_outgoing_port(window_alert, "Cool alert"),
    )
    TimePassed(_) -> #(
      Model(..model, time_counter: model.time_counter + 1),
      cmd.none(),
    )
  }
}

fn subscriptions(model: Model) {
  case model.time_counter < 20 {
    True -> time.every(1000.0, TimePassed)
    False -> sub.none()
  }
}

pub fn main(args) {
  debugger.element(
    init: init,
    view: view,
    update: update,
    flags_decoder: decode.succeed(Nil),
    subscriptions: subscriptions,
    effect_managers: [
      time.effect_manager(),
      platform.outgoing_port_to_effect_manager(window_alert),
    ],
  )(args)
}
