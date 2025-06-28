//// API to the core diffing algorithm. Can serve as a foundation for libraries
//// that expose more helper functions for HTML or SVG.
////
//// # Create
//// @docs Node, text, node, nodeNS
////
//// # Attributes
//// @docs Attribute, style, property, attribute, attributeNS
////
//// # Events
//// @docs on, Handler
////
//// # Routing Messages
//// @docs map, mapAttribute
////
//// # Keyed Nodes
//// @docs keyedNode, keyedNodeNS
////
//// # Lazy Nodes
//// @docs lazy, lazy2, lazy3, lazy4, lazy5, lazy6, lazy7, lazy8

import elm/json/decode.{type Decoder}
import elm/json/encode
import elm/platform.{type Program}

/// An immutable chunk of data representing a DOM node. This can be HTML or SVG.
pub type Node(msg)

/// Create a DOM node with a tag name, a list of HTML properties that can
/// include styles and event listeners, a list of CSS properties like `color`, and
/// a list of child nodes.
///
///     import Json.Encode as Json
///
///     hello : Node msg
///     hello =
///       node "div" [] [ text "Hello!" ]
///
///     greeting : Node msg
///     greeting =
///       node "div"
///         [ property "id" (Json.string "greeting") ]
///         [ text "Hello!" ]
pub fn node(
  tag: String,
  attributes: List(Attribute(msg)),
  children: List(Node(msg)),
) -> Node(msg) {
  node_raw(no_script(tag), attributes, children)
}

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_node")
fn node_raw(
  tag: String,
  attributes: List(Attribute(msg)),
  children: List(Node(msg)),
) -> Node(msg)

/// Create a namespaced DOM node. For example, an SVG `<path>` node could be
/// defined like this:
///
///     path : List (Attribute msg) -> List (Node msg) -> Node msg
///     path attrubutes children =
///       nodeNS "http://www.w3.org/2000/svg" "path" attributes children
pub fn node_ns(
  namespace: String,
  tag: String,
  attributes: List(Attribute(msg)),
  children: List(Node(msg)),
) -> Node(msg) {
  node_ns_raw(namespace, no_script(tag), attributes, children)
}

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_nodeNS")
fn node_ns_raw(
  namespace: String,
  tag: String,
  attributes: List(Attribute(msg)),
  children: List(Node(msg)),
) -> Node(msg)

/// Just put plain text in the DOM. It will escape the string so that it appears
/// exactly as you specify.
///
///     text "Hello World!"
@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_text")
pub fn text(text: String) -> Node(msg)

/// This function is useful when nesting components with [the Elm
/// Architecture](https://github.com/evancz/elm-architecture-tutorial/). It lets
/// you transform the messages produced by a subtree.
///
/// Say you have a node named `button` that produces `()` values when it is
/// clicked. To get your model updating properly, you will probably want to tag
/// this `()` value like this:
///
///     type Msg = Click | ...
///
///     update msg model =
///       case msg of
///         Click ->
///           ...
///
///     view model =
///       map (\_ -> Click) button
///
/// So now all the events produced by `button` will be transformed to be of type
/// `Msg` so they can be handled by your update function!
@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_map")
pub fn map(node: Node(a), tagger: fn(a) -> msg) -> Node(msg)

// ATTRIBUTES

/// When using HTML and JS, there are two ways to specify parts of a DOM node.
///
///   1. Attributes &mdash; You can set things in HTML itself. So the `class`
///      in `<div class="greeting"></div>` is called an *attribute*.
///
///   2. Properties &mdash; You can also set things in JS. So the `className`
///      in `div.className = 'greeting'` is called a *property*.
///
/// So the `class` attribute corresponds to the `className` property. At first
/// glance, perhaps this distinction is defensible, but it gets much crazier.
/// *There is not always a one-to-one mapping between attributes and properties!*
/// Yes, that is a true fact. Sometimes an attribute exists, but there is no
/// corresponding property. Sometimes changing an attribute does not change the
/// underlying property. For example, as of this writing, the `webkit-playsinline`
/// attribute can be used in HTML, but there is no corresponding property!
pub type Attribute(msg)

/// Specify a style.
///
///     greeting : Node msg
///     greeting =
///       node "div"
///         [ style "backgroundColor" "red"
///         , style "height" "90px"
///         , style "width" "100%"
///         ]
///         [ text "Hello!"
///         ]
@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_style")
pub fn style(key: String, value: String) -> Attribute(msg)

/// Create a property.
///
///     import Json.Encode as Encode
///
///     buttonLabel : Node msg
///     buttonLabel =
///       node "label" [ property "htmlFor" (Encode.string "button") ] [ text "Label" ]
///
/// Notice that you must give the *property* name, so we use `htmlFor` as it
/// would be in JavaScript, not `for` as it would appear in HTML.
pub fn property(key: String, value: encode.Value) -> Attribute(msg) {
  property_raw(
    no_inner_html_or_form_action(key),
    no_java_script_or_html_json(value),
  )
}

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_property")
fn property_raw(key: String, value: encode.Value) -> Attribute(msg)

/// Create an attribute. This uses JavaScript’s `setAttribute` function
/// behind the scenes.
///
///     buttonLabel : Node msg
///     buttonLabel =
///       node "label" [ attribute "for" "button" ] [ text "Label" ]
///
/// Notice that you must give the *attribute* name, so we use `for` as it would
/// be in HTML, not `htmlFor` as it would appear in JS.
pub fn attribute(key: String, value: String) -> Attribute(msg) {
  attribute_raw(no_on_or_form_action(key), no_java_script_or_html_uri(value))
}

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_attribute")
fn attribute_raw(key: String, value: String) -> Attribute(msg)

/// Would you believe that there is another way to do this?! This uses
/// JavaScript's `setAttributeNS` function behind the scenes. It is doing pretty
/// much the same thing as `attribute` but you are able to have namespaced
/// attributes. As an example, the `elm/svg` package defines an attribute
/// like this:
///
///     xlinkHref : String -> Attribute msg
///     xlinkHref value =
///       attributeNS "http://www.w3.org/1999/xlink" "xlink:href" value
pub fn attribute_ns(
  namespace: String,
  key: String,
  value: String,
) -> Attribute(msg) {
  attribute_ns_raw(
    namespace,
    no_on_or_form_action(key),
    no_java_script_or_html_uri(value),
  )
}

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_attributeNS")
fn attribute_ns_raw(
  namespace: String,
  key: String,
  value: String,
) -> Attribute(msg)

/// Transform the messages produced by a `Attribute`.
@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_mapAttribute")
pub fn map_attribute(
  attribute: Attribute(a),
  tagger: fn(a) -> b,
) -> Attribute(b)

// EVENTS

/// Create custom event handlers.
///
/// You can define `onClick` like this:
///
///     import Json.Decode as Decode
///
///     onClick : msg -> Attribute msg
///     onClick msg =
///       on "click" (Normal (Decode.succeed msg))
///
/// **Note:** These event handlers trigger in the bubble phase. You can learn more
/// about what that means [here][]. There is not support within Elm for doing
/// tricks with the capture phase. We recommend doing that in JS through ports.
///
/// [here]: https://github.com/elm/virtual-dom/blob/master/hints/capture-vs-bubble.md
pub fn on(event: String, handler: Handler(msg)) -> Attribute(msg) {
  on_raw(event, #(to_handler_tuple(handler), handler))
}

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_on_gleam")
fn on_raw(event: String, handler: #(Int, Handler(msg))) -> Attribute(msg)

/// When using `on` you can customize the event behavior
/// a bit. There are two ways to do this:
///
///   - [`stopPropagation`][sp] means the event stops traveling through the DOM.
///   So if propagation of a click is stopped, it will not trigger any other event
///   listeners.
///
///   - [`preventDefault`][pd] means any built-in browser behavior related to the
///   event is prevented. This can be handy with key presses or touch gestures.
///
/// **Note 1:** A [passive][] event listener will be created if you use `Normal`
/// or `MayStopPropagation`. In both cases `preventDefault` cannot be used, so
/// we can enable optimizations for touch, scroll, and wheel events in some
/// browsers.
///
/// **Note 2:** Some actions, like uploading and downloading files, are only
/// allowed when the JavaScript event loop is running because of user input. This
/// is for security! So when an event occurs, we call `update` and send any `port`
/// messages immediately, all within the same tick of the event loop. This makes
/// it possible to handle user-instigated events in ports.
///
/// **Note 3:** Normally the `view` is shown in the next `requestAnimationFrame`
/// call. This allows us to save some work if messages are coming in very quickly.
/// But if `stopPropagation` is used, we update the DOM immediately, within the
/// same tick of the event loop. This is useful for DOM nodes that hold their own
/// state, like `<input type="text">`. If someone types very fast, the state in the
/// DOM can diverge from the state in your `Model` while waiting on the next
/// `requestAnimationFrame` call. So updating the DOM synchronously makes this
/// divergence impossible.
///
/// [sp]: https://developer.mozilla.org/en-US/docs/Web/API/Event/stopPropagation
/// [pd]: https://developer.mozilla.org/en-US/docs/Web/API/Event/preventDefault
/// [passive]: https://github.com/WICG/EventListenerOptions/blob/gh-pages/explainer.md
pub type Handler(msg) {
  Normal(Decoder(msg))
  MayStopPropagation(Decoder(#(msg, Bool)))
  MayPreventDefault(Decoder(#(msg, Bool)))
  Custom(Decoder(CustomHandler(msg)))
}

pub type CustomHandler(msg) {
  CustomHandler(message: msg, stop_propagation: Bool, prevent_default: Bool)
}

// LAZY NODES

/// A performance optimization that delays the building of virtual DOM nodes.
///
/// Calling `(view model)` will definitely build some virtual DOM, perhaps a lot of
/// it. Calling `(lazy view model)` delays the call until later. During diffing, we
/// can check to see if `model` is referentially equal to the previous value used,
/// and if so, we just stop. No need to build up the tree structure and diff it,
/// we know if the input to `view` is the same, the output must be the same!
@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy")
pub fn lazy(func: fn(a) -> Node(msg), a: a) -> Node(msg)

// TODO: Finish lazy2 to lazy8

/// Same as `lazy` but checks on two arguments.
// @external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy2")
// pub fn lazy2((a -> b -> Node msg) -> a -> b) -> Node msg

/// Same as `lazy` but checks on three arguments.
// @external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy3")
// pub fn lazy3((a -> b -> c -> Node msg) -> a -> b -> c) -> Node msg

/// Same as `lazy` but checks on four arguments.
// @external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy4")
// pub fn lazy4((a -> b -> c -> d -> Node msg) -> a -> b -> c -> d) -> Node msg

/// Same as `lazy` but checks on five arguments.
// @external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy5")
// pub fn lazy5((a -> b -> c -> d -> e -> Node msg) -> a -> b -> c -> d -> e) -> Node msg

/// Same as `lazy` but checks on six arguments.
// @external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy6")
// pub fn lazy6((a -> b -> c -> d -> e -> f -> Node msg) -> a -> b -> c -> d -> e -> f) -> Node msg

/// Same as `lazy` but checks on seven arguments.
// @external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy7")
// pub fn lazy7((a -> b -> c -> d -> e -> f -> g -> Node msg) -> a -> b -> c -> d -> e -> f -> g) -> Node msg

/// Same as `lazy` but checks on eight arguments.
// @external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy8")
// pub fn lazy8((a -> b -> c -> d -> e -> f -> g -> h -> Node msg) -> a -> b -> c -> d -> e -> f -> g -> h) -> Node msg

// KEYED NODES

/// Works just like `node`, but you add a unique identifier to each child
/// node. You want this when you have a list of nodes that is changing: adding
/// nodes, removing nodes, etc. In these cases, the unique identifiers help make
/// the DOM modifications more efficient.
pub fn keyed_node(
  tag: String,
  attributes: List(Attribute(msg)),
  children: List(#(String, Node(msg))),
) -> Node(msg) {
  keyed_node_raw(no_script(tag), attributes, children)
}

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_keyedNode")
fn keyed_node_raw(
  tag: String,
  attributes: List(Attribute(msg)),
  children: List(#(String, Node(msg))),
) -> Node(msg)

/// Create a keyed and namespaced DOM node. For example, an SVG `<g>` node
/// could be defined like this:
///
///     g : List (Attribute msg) -> List ( String, Node msg ) -> Node msg
///     g =
///       keyedNodeNS "http://www.w3.org/2000/svg" "g"
pub fn keyed_node_ns(
  namespace: String,
  tag: String,
  attributes: List(Attribute(msg)),
  children: List(#(String, Node(msg))),
) -> Node(msg) {
  keyed_node_ns_raw(namespace, no_script(tag), attributes, children)
}

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_keyedNodeNS")
fn keyed_node_ns_raw(
  namespace: String,
  tag: String,
  attributes: List(Attribute(msg)),
  children: List(#(String, Node(msg))),
) -> Node(msg)

// FOR INTERNAL USE ONLY

fn to_handler_tuple(handler: Handler(msg)) -> Int {
  case handler {
    Normal(_) -> 0
    MayStopPropagation(_) -> 1
    MayPreventDefault(_) -> 2
    Custom(_) -> 3
  }
}

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_noScript")
fn no_script(tag: String) -> String

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_noInnerHtmlOrFormAction")
fn no_inner_html_or_form_action(key: String) -> String

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_noJavaScriptOrHtmlJson")
fn no_java_script_or_html_json(value: encode.Value) -> encode.Value

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_noJavaScriptOrHtmlUri")
fn no_java_script_or_html_uri(key: String) -> String

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_noOnOrFormAction")
fn no_on_or_form_action(key: String) -> String

// GLEAM EXTENSION

@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_init")
pub fn init(node: Node(msg)) -> Program(Nil, Nil, Nil)
