import elm/html.{type Html, div, span, text}
import elm/html/attributes.{id, style}
import elm/html/events.{on_click}
import elm/virtual_dom as v
import gleam/float
import gleam/int
import gleam/string

// BLOCKERS

pub type BlockerType {
  BlockNone
  BlockMost
  BlockAll
}

pub fn to_blocker_type(is_paused: Bool) -> BlockerType {
  case is_paused {
    True -> BlockAll
    False -> BlockNone
  }
}

// VIEW

pub type Config(msg) {
  Config(resume: msg, open: msg)
}

pub fn view(
  config: Config(msg),
  is_paused: Bool,
  is_open: Bool,
  num_msgs: Int,
) -> Html(msg) {
  case is_open {
    True -> text("")

    False ->
      case is_paused {
        True ->
          div(
            [
              id("elm-debugger-overlay"),
              style("position", "fixed"),
              style("top", "0"),
              style("left", "0"),
              style("width", "100vw"),
              style("height", "100vh"),
              style("cursor", "pointer"),
              style("display", "flex"),
              style("align-items", "center"),
              style("justify-content", "center"),
              style("pointer-events", "auto"),
              style("background-color", "rgba(200, 200, 200, 0.7)"),
              style("color", "white"),
              style(
                "font-family",
                "'Trebuchet MS', 'Lucida Grande', 'Bitstream Vera Sans', 'Helvetica Neue', sans-serif",
              ),
              style("z-index", "2147483646"),
              on_click(config.resume),
            ],
            [
              span([style("font-size", "80px")], [text("Click to Resume")]),
              view_mini_controls(config, num_msgs),
            ],
          )

        False -> view_mini_controls(config, num_msgs)
      }
  }
}

// VIEW MINI CONTROLS

pub fn view_mini_controls(config: Config(msg), num_msgs: Int) -> Html(msg) {
  let str = int.to_string(num_msgs)
  let width = int.to_string(2 + string.length(str))
  div(
    [
      style("position", "fixed"),
      style("bottom", "2em"),
      style("right", "2em"),
      style("width", "calc(42px + " <> width <> "ch)"),
      style("height", "36px"),
      style("background-color", "#1293D8"),
      style("color", "white"),
      style("font-family", "monospace"),
      style("pointer-events", "auto"),
      style("z-index", "2147483647"),
      style("display", "flex"),
      style("justify-content", "center"),
      style("align-items", "center"),
      style("cursor", "pointer"),
      on_click(config.open),
    ],
    [
      elm_logo(),
      span(
        [
          style("padding-left", "calc(1ch + 6px)"),
          style("padding-right", "1ch"),
        ],
        [text(str)],
      ),
    ],
  )
}

fn elm_logo() -> Html(msg) {
  v.node_ns(
    "http://www.w3.org/2000/svg",
    "svg",
    [
      v.attribute("viewBox", "-300 -300 600 600"),
      v.attribute("xmlns", "http://www.w3.org/2000/svg"),
      v.attribute("fill", "currentColor"),
      v.attribute("width", "24px"),
      v.attribute("height", "24px"),
    ],
    [
      v.node_ns(
        "http://www.w3.org/2000/svg",
        "g",
        [v.attribute("transform", "scale(1 -1)")],
        [
          view_shape(0.0, -210.0, 0.0, "-280,-90 0,190 280,-90"),
          view_shape(-210.0, 0.0, 90.0, "-280,-90 0,190 280,-90"),
          view_shape(207.0, 207.0, 45.0, "-198,-66 0,132 198,-66"),
          view_shape(150.0, 0.0, 0.0, "-130,0 0,-130 130,0 0,130"),
          view_shape(-89.0, 239.0, 0.0, "-191,61 69,61 191,-61 -69,-61"),
          view_shape(0.0, 106.0, 180.0, "-130,-44 0,86  130,-44"),
          view_shape(256.0, -150.0, 270.0, "-130,-44 0,86  130,-44"),
        ],
      ),
    ],
  )
}

fn view_shape(
  x: Float,
  y: Float,
  angle: Float,
  coordinates: String,
) -> Html(msg) {
  v.node_ns(
    "http://www.w3.org/2000/svg",
    "polygon",
    [
      v.attribute("points", coordinates),
      v.attribute(
        "transform",
        "translate("
          <> float.to_string(x)
          <> " "
          <> float.to_string(y)
          <> ") rotate("
          <> float.to_string(float.negate(angle))
          <> ")",
      ),
    ],
    [],
  )
}
