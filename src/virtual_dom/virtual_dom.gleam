pub type Program

pub type Node(msg)

pub type Attribute(msg)

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_init")
pub fn init(node: Node(msg)) -> Program

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_attribute_")
pub fn attribute(key: String, value: String) -> Attribute(msg)

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_text")
pub fn text(text: String) -> Node(msg)

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_node_")
pub fn node(
  tag: String,
  attributes: List(Attribute(msg)),
  children: List(Node(msg)),
) -> Node(msg)
