import core/platform.{type Program}
import json/decode.{type Decoder}

pub type Node(msg)

pub type Attribute(msg)

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_init")
pub fn init(node: Node(msg)) -> Program(Nil, Nil)

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
  Custom(Decoder(CustomHandler))
}

pub type CustomHandler {
  CustomHandler(message: msg, stopPropagation: Bool, preventDefault: Bool)
}

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_on")
pub fn on(event: String, handler: Handler) -> Node(msg)
