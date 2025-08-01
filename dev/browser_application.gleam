import elm/browser
import elm/browser/navigation
import elm/debugger
import elm/html
import elm/html/events
import elm/json/decode
import elm/json/encode
import elm/platform
import elm/platform/cmd
import elm/task
import elm/time
import gleam/function
import gleam/int

fn port_on_count() -> platform.OutgoingPort(Int) {
  platform.outgoing_port("onCount", encode.int)
}

fn port_on_js_message() -> platform.IncomingPort(String) {
  platform.incoming_port("onJsMessage", decode.string())
}

pub type Model {
  Model(key: navigation.Key, count: Int)
}

pub fn main(args) {
  debugger.application(
    flags_decoder: decode.succeed(Nil),
    init: fn(_, _, key) { #(Model(key:, count: 0), cmd.none()) },
    view: fn(model) {
      browser.Document(title: "Gleam Elm application", body: [
        html.button([events.on_click(Nil)], [
          html.text(int.to_string(model.count)),
        ]),
      ])
    },
    update: fn(msg, model) {
      case msg {
        Nil -> #(Model(..model, count: model.count + 1), case model.count {
          1 -> navigation.push_url(model.key, "/test")
          2 -> task.perform(function.identity, task.succeed(Nil))
          _ -> platform.call_outgoing_port(port_on_count, model.count + 1)
        })
      }
    },
    subscriptions: fn(model) {
      case model.count {
        6 | 7 | 8 | 9 -> time.every(1000.0, fn(_) { Nil })
        _ ->
          platform.subscribe_incoming_port(port_on_js_message, fn(js_message) {
            echo js_message
            Nil
          })
      }
    },
    on_url_request: fn(_) { Nil },
    on_url_change: fn(_) { Nil },
    effect_managers: [
      time.effect_manager(),
      platform.outgoing_port_to_effect_manager(port_on_count),
      platform.incoming_port_to_effect_manager(port_on_js_message),
    ],
  )(args)
}
