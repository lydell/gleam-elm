import elm/debugger
import elm/html
import elm/html/events
import elm/json/decode
import elm/json/encode
import elm/platform
import elm/platform/cmd
import elm/platform/sub
import elm/task
import elm/time
import gleam/int

fn view(model: Model) {
  html.div([], [
    html.text("Hello Elm Camp!"),
    html.button([events.on_click(IncrementPressed)], [
      html.text(int.to_string(model.counter)),
    ]),
    html.div([], [html.text(int.to_string(model.time_counter))]),
  ])
}

pub type Model {
  Model(counter: Int, time_counter: Int)
}

fn init(_) -> #(Model, cmd.Cmd(Msg)) {
  #(Model(counter: 0, time_counter: 0), cmd.none())
}

pub type Msg {
  IncrementPressed
  TimePassed
}

fn window_alert() {
  platform.outgoing_port("windowAlert", encode.string)
}

fn update(msg: Msg, model: Model) -> #(Model, cmd.Cmd(Msg)) {
  case msg {
    IncrementPressed -> #(
      Model(..model, counter: model.counter + 1),
      platform.call_outgoing_port(window_alert, "Cool alert"),
    )
    TimePassed -> #(
      Model(..model, time_counter: model.time_counter + 1),
      cmd.none(),
    )
  }
}

fn subscriptions(model: Model) {
  case model.time_counter < 5 {
    True -> time.every(1000.0, fn(_) { TimePassed })
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
      // TODO: Currently you have to manually add `task.effect_manager()` if you use the debugger.
      task.effect_manager(),
      time.effect_manager(),
      platform.outgoing_port_to_effect_manager(window_alert),
    ],
  )(args)
}
