//// Helper functions for HTML attributes. They are organized roughly by
//// category. Each attribute is labeled with the HTML tags it can be used with, so
//// just search the page for `video` if you want video stuff.
////
//// # Less Common Global Attributes
//// Attributes that can be attached to any HTML tag but are less commonly used.

import elm/html.{type Attribute}
import elm/json/encode
import elm/virtual_dom
import gleam/int
import gleam/list
import gleam/string

// This library does not include low, high, or optimum because the idea of a
// `meter` is just too crazy.

// PRIMITIVES

/// Specify a style.
///
///     fn greeting() -> Node(msg) {
///       div([
///         style("background-color", "red"),
///         style("height", "90px"),
///         style("width", "100%"),
///       ], [
///         text("Hello!"),
///       ])
///     }
///
/// There is no `Html.Styles` module because best practices for working with HTML
/// suggest that this should primarily be specified in CSS files. So the general
/// recommendation is to use this function lightly.
pub fn style(key: String, value: String) -> Attribute(msg) {
  virtual_dom.style(key, value)
}

/// This function makes it easier to build a space-separated class attribute.
/// Each class can easily be added and removed depending on the boolean value it
/// is paired with. For example, maybe we want a way to view notices:
///
///     fn view_notice(notice: Notice) -> Html(msg) {
///       div([
///         class_list([
///           #("notice", True),
///           #("notice-important", notice.is_important),
///           #("notice-seen", notice.is_seen),
///         ]),
///       ], [
///         text(notice.content),
///       ])
///     }
///
/// **Note:** You can have as many `class` and `classList` attributes as you want.
/// They all get applied, so if you say `[ class "notice", class "notice-seen" ]`
/// you will get both classes!
pub fn class_list(classes: List(#(String, Bool))) -> Attribute(msg) {
  class(string.join(
    list.map(list.filter(classes, fn(tuple) { tuple.1 }), fn(tuple) { tuple.0 }),
    " ",
  ))
}

// CUSTOM ATTRIBUTES

/// Create *properties*, like saying `domNode.className = 'greeting'` in
/// JavaScript.
///
///     import elm/json/encode
///
///     fn class(name: String) -> Attribute(msg) {
///       property("className", encode.string(name))
///     }
///
/// Read more about the difference between properties and attributes [here][].
///
/// [here]: https://github.com/elm/html/blob/master/properties-vs-attributes.md
pub fn property(key: String, value: encode.Value) -> Attribute(msg) {
  virtual_dom.property(key, value)
}

/// This is used for attributes that have a property that:
///
/// - Is boolean.
/// - Defaults to `false`.
/// - Removes the attribute when setting to `false`.
///
/// Note:
///
/// - Some properties, like `checked`, can be modified by the user.
/// - `.setAttribute(property, "false")` does not set the property to `false` – we have to remove the attribute. (Except `spellcheck` which explicitly has a "false" (and "true") value.)
///
/// Consider `hidden : Bool -> Attribute msg`. When that `Bool` is `True`, we could implement the function with `attribute "hidden" ""`. (Using the empty string seems to be “canonical”, but any string would make the element hidden.) But what do we do when the `Bool` is `False`? The intention is to make the element _not_ hidden. The only way of doing that is to remove the `hidden` attribute, but we cannot do that with `attribute` – it always results in the attribute being present (we can only choose its value, but no value will result in the element _not_ being hidden). To keep this API, we _have_ to use the `hidden` _property_ instead, which (like mentioned above) automatically removes the attribute when set to `false`.
///
/// An alternative would be to have `hidden : Attribute msg` and let users do `if shouldHide then hidden else ???` where `???` would have to be a way to express a no-op `Attribute msg`, or the user has to resort to list manipulation.
fn bool_property(key: String, bool: Bool) -> Attribute(msg) {
  property_raw(key, encode.bool(bool))
}

/// Create *attributes*, like saying `domNode.setAttribute('class', 'greeting')`
/// in JavaScript.
///
///     fn class(name: String) -> Attribute(msg) {
///       attribute("class", name)
///     }
///
/// Read more about the difference between properties and attributes [here][].
///
/// [here]: https://github.com/elm/html/blob/master/properties-vs-attributes.md
pub fn attribute(key: String, value: String) -> Attribute(msg) {
  virtual_dom.attribute(key, value)
}

/// Transform the messages produced by an `Attribute`.
pub fn map(attribute: Attribute(a), tagger: fn(a) -> msg) -> Attribute(msg) {
  virtual_dom.map_attribute(attribute, tagger)
}

// GLOBAL ATTRIBUTES

/// Often used with CSS to style elements with common properties.
///
/// **Note:** You can have as many `class` and `classList` attributes as you want.
/// They all get applied, so if you say `[ class "notice", class "notice-seen" ]`
/// you will get both classes!
pub fn class(value: String) {
  attribute_raw("class", value)
}

/// Indicates the relevance of an element.
pub fn hidden(value: Bool) {
  bool_property("hidden", value)
}

/// Often used with CSS to style a specific element. The value of this
/// attribute must be unique.
pub fn id(value: String) {
  attribute_raw("id", value)
}

/// Text to be displayed in a tooltip when hovering over the element.
pub fn title(value: String) {
  attribute_raw("title", value)
}

// LESS COMMON GLOBAL ATTRIBUTES

/// Defines a keyboard shortcut to activate or add focus to the element.
pub fn accesskey(char: String) {
  attribute_raw("accesskey", char)
}

/// Indicates whether the element's content is editable.
///
/// Note: These days, the contenteditable attribute can take more values than a boolean, like "inherit" and "plaintext-only". You can set those values like this:
///
///     attribute("contenteditable", "inherit")
pub fn contenteditable(bool: Bool) -> Attribute(msg) {
  // Note: `node.contentEditable = 'bad'` throws an error!
  attribute_raw("contenteditable", case bool {
    True -> "true"
    False -> "false"
  })
}

/// Defines the ID of a `menu` element which will serve as the element's
/// context menu.
pub fn contextmenu(value: String) {
  attribute_raw("contextmenu", value)
}

/// Defines the text direction. Allowed values are ltr (Left-To-Right) or rtl
/// (Right-To-Left).
pub fn dir(value: String) {
  attribute_raw("dir", value)
}

/// Defines whether the element can be dragged.
pub fn draggable(value: String) {
  attribute_raw("draggable", value)
}

/// Indicates that the element accept the dropping of content on it.
///
/// Note: This attribute or property seems to no longer exist.
pub fn dropzone(value: String) {
  attribute_raw("dropzone", value)
}

///
pub fn itemprop(value: String) {
  attribute_raw("itemprop", value)
}

/// Defines the language used in the element.
pub fn lang(value: String) {
  attribute_raw("lang", value)
}

/// Indicates whether spell checking is allowed for the element.
pub fn spellcheck(bool: Bool) -> Attribute(msg) {
  // Note: The spellcheck _property_ defaults to `true`, unlike other boolean properties.
  // Setting it back to the default value does _not_ remove the attribute.
  // Because of this, we set it using an attribute instead.
  attribute_raw("spellcheck", case bool {
    True -> "true"
    False -> "false"
  })
}

/// Overrides the browser's default tab order and follows the one specified
/// instead.
pub fn tabindex(n: Int) {
  attribute_raw("tabIndex", int.to_string(n))
}

// EMBEDDED CONTENT

/// The URL of the embeddable content. For `audio`, `embed`, `iframe`, `img`,
/// `input`, `script`, `source`, `track`, and `video`.
pub fn src(url: String) {
  attribute_raw("src", no_java_script_or_html_uri(url))
}

/// Declare the height of a `canvas`, `embed`, `iframe`, `img`, `input`,
/// `object`, or `video`.
pub fn height(n: Int) {
  attribute_raw("height", int.to_string(n))
}

/// Declare the width of a `canvas`, `embed`, `iframe`, `img`, `input`,
/// `object`, or `video`.
pub fn width(n: Int) {
  attribute_raw("width", int.to_string(n))
}

/// Alternative text in case an image can't be displayed. Works with `img`,
/// `area`, and `input`.
pub fn alt(value: String) {
  attribute_raw("alt", value)
}

// AUDIO and VIDEO

/// The `audio` or `video` should play as soon as possible.
pub fn autoplay(value: Bool) {
  bool_property("autoplay", value)
}

/// Indicates whether the browser should show playback controls for the `audio`
/// or `video`.
pub fn controls(value: Bool) {
  bool_property("controls", value)
}

/// Indicates whether the `audio` or `video` should start playing from the
/// start when it's finished.
pub fn loop(value: Bool) {
  bool_property("loop", value)
}

/// Control how much of an `audio` or `video` resource should be preloaded.
pub fn preload(value: String) {
  attribute_raw("preload", value)
}

/// A URL indicating a poster frame to show until the user plays or seeks the
/// `video`.
pub fn poster(value: String) {
  attribute_raw("poster", value)
}

/// Indicates that the `track` should be enabled unless the user's preferences
/// indicate something different.
pub fn default(value: Bool) {
  bool_property("default", value)
}

/// Specifies the kind of text `track`.
pub fn kind(value: String) {
  attribute_raw("kind", value)
}

// TODO: maybe reintroduce once there's a better way to disambiguate imports
/// Specifies a user-readable title of the text `track`.
// pub fn label(value: String) {
//   attribute_raw("label", value)
// }

/// A two letter language code indicating the language of the `track` text data.
pub fn srclang(value: String) {
  attribute_raw("srclang", value)
}

// IFRAMES

/// A space separated list of security restrictions you'd like to lift for an
/// `iframe`.
pub fn sandbox(value: String) {
  attribute_raw("sandbox", value)
}

/// An HTML document that will be displayed as the body of an `iframe`. It will
/// override the content of the `src` attribute if it has been specified.
pub fn srcdoc(value: String) {
  attribute_raw("srcdoc", value)
}

// INPUT

/// Defines the type of a `button`, `checkbox`, `input`, `embed`, `menu`,
/// `object`, `script`, `source`, or `style`.
pub fn type_(value: String) {
  attribute_raw("type", value)
}

/// Defines a default value which will be displayed in a `button`, `option`,
/// `input`, `li`, `meter`, `progress`, or `param`.
pub fn value(string: String) -> Attribute(msg) {
  // Note: `.value` has no corresponding attribute, so we have to set it
  // using a property. It can also be modified by the user by typing in inputs.
  // Properties are diffed against the actual DOM, not the virtual DOM, so
  // this ensures that the DOM is up-to-date with the model.
  virtual_dom.property("value", encode.string(string))
}

/// Indicates whether an `input` of type checkbox is checked.
pub fn checked(value: Bool) {
  bool_property("checked", value)
}

/// Provides a hint to the user of what can be entered into an `input` or
/// `textarea`.
pub fn placeholder(value: String) {
  attribute_raw("placeholder", value)
}

/// Defines which `option` will be selected on page load.
pub fn selected(value: Bool) {
  bool_property("selected", value)
}

// INPUT HELPERS

/// List of types the server accepts, typically a file type.
/// For `input`.
pub fn accept(value: String) {
  attribute_raw("accept", value)
}

/// List of supported charsets in a `form`.
pub fn accept_c_harset(value: String) {
  attribute_raw("accept-charset", value)
}

/// The URI of a program that processes the information submitted via a `form`.
pub fn action(uri: String) {
  attribute_raw("action", no_java_script_uri(uri))
}

/// Indicates whether a `form` or an `input` can have their values automatically
/// completed by the browser.
///
/// Note: These days, the autocomplete attribute can take more values than a boolean. For example, you can use this to autocomplete a street address:
///
///     attribute("autocomplete", "street-address")
pub fn autocomplete(bool: Bool) -> Attribute(msg) {
  attribute_raw("autocomplete", case bool {
    True -> "on"
    False -> "off"
  })
}

/// The element should be automatically focused after the page loaded.
/// For `button`, `input`, `select`, and `textarea`.
pub fn autofocus(value: Bool) {
  bool_property("autofocus", value)
}

/// Indicates whether the user can interact with a `button`, `fieldset`,
/// `input`, `optgroup`, `option`, `select` or `textarea`.
pub fn disabled(value: Bool) {
  bool_property("disabled", value)
}

/// How `form` data should be encoded when submitted with the POST method.
/// Options include: application/x-www-form-urlencoded, multipart/form-data, and
/// text/plain.
pub fn enctype(value: String) {
  attribute_raw("enctype", value)
}

/// Associates an `input` with a `datalist` tag. The datalist gives some
/// pre-defined options to suggest to the user as they interact with an input.
/// The value of the list attribute must match the id of a `datalist` node.
/// For `input`.
pub fn list(value: String) {
  attribute_raw("list", value)
}

/// Defines the minimum number of characters allowed in an `input` or
/// `textarea`.
pub fn minlength(n: Int) {
  attribute_raw("minLength", int.to_string(n))
}

/// Defines the maximum number of characters allowed in an `input` or
/// `textarea`.
pub fn maxlength(n: Int) {
  attribute_raw("maxlength", int.to_string(n))
}

/// Defines which HTTP method to use when submitting a `form`. Can be GET
/// (default) or POST.
pub fn method(value: String) {
  attribute_raw("method", value)
}

/// Indicates whether multiple values can be entered in an `input` of type
/// email or file. Can also indicate that you can `select` many options.
pub fn multiple(value: Bool) {
  bool_property("multiple", value)
}

/// Name of the element. For example used by the server to identify the fields
/// in form submits. For `button`, `form`, `fieldset`, `iframe`, `input`,
/// `object`, `output`, `select`, `textarea`, `map`, `meta`, and `param`.
pub fn name(value: String) {
  attribute_raw("name", value)
}

/// This attribute indicates that a `form` shouldn't be validated when
/// submitted.
pub fn novalidate(value: Bool) {
  bool_property("noValidate", value)
}

/// Defines a regular expression which an `input`'s value will be validated
/// against.
pub fn pattern(value: String) {
  attribute_raw("pattern", value)
}

/// Indicates whether an `input` or `textarea` can be edited.
pub fn readonly(value: Bool) {
  bool_property("readOnly", value)
}

/// Indicates whether this element is required to fill out or not.
/// For `input`, `select`, and `textarea`.
pub fn required(value: Bool) {
  bool_property("required", value)
}

/// For `input` specifies the width of an input in characters.
///
/// For `select` specifies the number of visible options in a drop-down list.
pub fn size(n: Int) {
  attribute_raw("size", int.to_string(n))
}

/// The element ID described by this `label` or the element IDs that are used
/// for an `output`.
pub fn for(value: String) {
  attribute_raw("for", value)
}

/// Indicates the element ID of the `form` that owns this particular `button`,
/// `fieldset`, `input`, `label`, `meter`, `object`, `output`, `progress`,
/// `select`, or `textarea`.
pub fn form(value: String) {
  attribute_raw("form", value)
}

// RANGES

/// Indicates the maximum value allowed. When using an input of type number or
/// date, the max value must be a number or date. For `input`, `meter`, and `progress`.
pub fn max(value: String) {
  attribute_raw("max", value)
}

/// Indicates the minimum value allowed. When using an input of type number or
/// date, the min value must be a number or date. For `input` and `meter`.
pub fn min(value: String) {
  attribute_raw("min", value)
}

/// Add a step size to an `input`. Use `step "any"` to allow any floating-point
/// number to be used in the input.
pub fn step(n: String) -> Attribute(msg) {
  attribute_raw("step", n)
}

//------------------------

/// Defines the number of columns in a `textarea`.
pub fn cols(n: Int) {
  attribute_raw("cols", int.to_string(n))
}

/// Defines the number of rows in a `textarea`.
pub fn rows(n: Int) {
  attribute_raw("rows", int.to_string(n))
}

/// Indicates whether the text should be wrapped in a `textarea`. Possible
/// values are "hard" and "soft".
pub fn wrap(value: String) {
  attribute_raw("wrap", value)
}

// MAPS

/// When an `img` is a descendant of an `a` tag, the `ismap` attribute
/// indicates that the click location should be added to the parent `a`'s href as
/// a query string.
pub fn ismap(value: Bool) {
  bool_property("isMap", value)
}

/// Specify the hash name reference of a `map` that should be used for an `img`
/// or `object`. A hash name reference is a hash symbol followed by the element's name or id.
/// E.g. `"#planet-map"`.
pub fn usemap(value: String) {
  attribute_raw("usemap", value)
}

/// Declare the shape of the clickable area in an `a` or `area`. Valid values
/// include: default, rect, circle, poly. This attribute can be paired with
/// `coords` to create more particular shapes.
pub fn shape(value: String) {
  attribute_raw("shape", value)
}

/// A set of values specifying the coordinates of the hot-spot region in an
/// `area`. Needs to be paired with a `shape` attribute to be meaningful.
pub fn coords(value: String) {
  attribute_raw("coords", value)
}

// REAL STUFF

/// Specifies the horizontal alignment of a `caption`, `col`, `colgroup`,
/// `hr`, `iframe`, `img`, `table`, `tbody`,  `td`,  `tfoot`, `th`, `thead`, or
/// `tr`.
pub fn align(value: String) {
  attribute_raw("align", value)
}

/// Contains a URI which points to the source of the quote or change in a
/// `blockquote`, `del`, `ins`, or `q`.
pub fn cite(value: String) {
  attribute_raw("cite", value)
}

// LINKS AND AREAS

/// The URL of a linked resource, such as `a`, `area`, `base`, or `link`.
pub fn href(url: String) {
  attribute_raw("href", no_java_script_uri(url))
}

/// Specify where the results of clicking an `a`, `area`, `base`, or `form`
/// should appear. Possible special values include:
///
///   * _blank &mdash; a new window or tab
///   * _self &mdash; the same frame (this is default)
///   * _parent &mdash; the parent frame
///   * _top &mdash; the full body of the window
///
/// You can also give the name of any `frame` you have created.
pub fn target(value: String) {
  attribute_raw("target", value)
}

/// Indicates that clicking an `a` and `area` will download the resource
/// directly. The `String` argument determins the name of the downloaded file.
/// Say the file you are serving is named `hats.json`.
///
///     download("")               // hats.json
///     download("my-hats.json")   // my-hats.json
///     download("snakes.json")    // snakes.json
///
/// The empty `String` says to just name it whatever it was called on the server.
pub fn download(file_name: String) -> Attribute(msg) {
  attribute_raw("download", file_name)
}

/// Two-letter language code of the linked resource of an `a`, `area`, or `link`.
pub fn hreflang(value: String) {
  attribute_raw("hreflang", value)
}

/// Specifies a hint of the target media of a `a`, `area`, `link`, `source`,
/// or `style`.
pub fn media(value: String) {
  attribute_raw("media", value)
}

/// Specify a URL to send a short POST request to when the user clicks on an
/// `a` or `area`. Useful for monitoring and tracking.
pub fn ping(value: String) {
  attribute_raw("ping", value)
}

/// Specifies the relationship of the target object to the link object.
/// For `a`, `area`, `link`.
pub fn rel(value: String) {
  attribute_raw("rel", value)
}

// CRAZY STUFF

/// Indicates the date and time associated with the element.
/// For `del`, `ins`, `time`.
pub fn datetime(value: String) {
  attribute_raw("datetime", value)
}

/// Indicates whether this date and time is the date of the nearest `article`
/// ancestor element. For `time`.
pub fn pubdate(value: String) {
  attribute_raw("pubdate", value)
}

// ORDERED LISTS

/// Indicates whether an ordered list `ol` should be displayed in a descending
/// order instead of a ascending.
pub fn reversed(value: Bool) {
  bool_property("reversed", value)
}

/// Defines the first number of an ordered list if you want it to be something
/// besides 1.
pub fn start(n: Int) {
  attribute_raw("start", int.to_string(n))
}

// TABLES

/// The colspan attribute defines the number of columns a cell should span.
/// For `td` and `th`.
pub fn colspan(n: Int) {
  attribute_raw("colspan", int.to_string(n))
}

/// A space separated list of element IDs indicating which `th` elements are
/// headers for this cell. For `td` and `th`.
pub fn headers(value: String) {
  attribute_raw("headers", value)
}

/// Defines the number of rows a table cell should span over.
/// For `td` and `th`.
pub fn rowspan(n: Int) {
  attribute_raw("rowspan", int.to_string(n))
}

/// Specifies the scope of a header cell `th`. Possible values are: col, row,
/// colgroup, rowgroup.
pub fn scope(value: String) {
  attribute_raw("scope", value)
}

/// Specifies the URL of the cache manifest for an `html` tag.
pub fn manifest(value: String) {
  attribute_raw("manifest", value)
}

// TODO: maybe reintroduce once there's a better way to disambiguate imports
/// The number of columns a `col` or `colgroup` should span.
// pub fn span(n: Int) -> Attribute(msg) {
//   attribute_raw("span", int.to_string(n))
// }

// INTERNAL

@external(javascript, "../virtual_dom.ffi.mjs", "_VirtualDom_attribute")
fn attribute_raw(key: String, value: String) -> Attribute(msg)

@external(javascript, "../virtual_dom.ffi.mjs", "_VirtualDom_property")
fn property_raw(key: String, value: encode.Value) -> Attribute(msg)

@external(javascript, "../virtual_dom.ffi.mjs", "_VirtualDom_noJavaScriptOrHtmlUri")
fn no_java_script_or_html_uri(key: String) -> String

@external(javascript, "../virtual_dom.ffi.mjs", "_VirtualDom_noJavaScriptUri")
fn no_java_script_uri(key: String) -> String
