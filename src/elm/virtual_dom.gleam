import elm/json/decode.{type Decoder}
import elm/platform.{type Program}

pub type Node(msg)

pub type Attribute(msg)

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_init")
pub fn init(node: Node(msg)) -> Program(Nil, Nil, Nil)

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_attribute")
pub fn attribute(key: String, value: String) -> Attribute(msg)

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_text")
pub fn text(text: String) -> Node(msg)

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_node")
pub fn node(
  tag: String,
  attributes: List(Attribute(msg)),
  children: List(Node(msg)),
) -> Node(msg)

pub type Handler(msg) {
  Normal(Decoder(msg))
  MayStopPropagation(Decoder(#(msg, Bool)))
  MayPreventDefault(Decoder(#(msg, Bool)))
  Custom(Decoder(CustomHandler(msg)))
}

pub type CustomHandler(msg) {
  CustomHandler(message: msg, stop_propagation: Bool, prevent_default: Bool)
}

pub fn on(event: String, handler: Handler(msg)) -> Attribute(msg) {
  on_external(event, #(to_handler_tuple(handler), handler))
}

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_on_gleam")
fn on_external(event: String, handler: #(Int, Handler(msg))) -> Attribute(msg)

fn to_handler_tuple(handler: Handler(msg)) -> Int {
  case handler {
    Normal(_) -> 0
    MayStopPropagation(_) -> 1
    MayPreventDefault(_) -> 2
    Custom(_) -> 3
  }
}
