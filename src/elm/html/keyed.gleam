//// A keyed node helps optimize cases where children are getting added, moved,
//// removed, etc. Common examples include:
////
////   - The user can delete items from a list.
////   - The user can create new items in a list.
////   - You can sort a list based on name or date or whatever.
////
//// When you use a keyed node, every child is paired with a string identifier. This
//// makes it possible for the underlying diffing algorithm to reuse nodes more
//// efficiently.

import elm/html.{type Attribute, type Html}

/// Works just like `Html.node`, but you add a unique identifier to each child
/// node. You want this when you have a list of nodes that is changing: adding
/// nodes, removing nodes, etc. In these cases, the unique identifiers help make
/// the DOM modifications more efficient.
@external(javascript, "../virtual_dom.ffi.mjs", "_VirtualDom_keyedNode")
pub fn node(
  tag: String,
  attributes: List(Attribute(msg)),
  children: List(#(String, Html(msg))),
) -> Html(msg)

///
pub fn ol(
  attributes: List(Attribute(msg)),
  children: List(#(String, Html(msg))),
) -> Html(msg) {
  node("ol", attributes, children)
}

///
pub fn ul(
  attributes: List(Attribute(msg)),
  children: List(#(String, Html(msg))),
) -> Html(msg) {
  node("ul", attributes, children)
}
