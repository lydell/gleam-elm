//// This file is organized roughly in order of popularity. The tags which you'd
//// expect to use frequently will be closer to the top.
////

import elm/virtual_dom

// CORE TYPES

/// The core building block used to build up HTML. Here we create an `Html`
/// value with no attributes and one child:
///
///     fn hello() -> Html(msg) {
///       div([], [text("Hello!")])
///     }
pub type Html(msg) =
  virtual_dom.Node(msg)

/// Set attributes on your `Html`. Learn more in the
/// [`Html.Attributes`](Html-Attributes) module.
pub type Attribute(msg) =
  virtual_dom.Attribute(msg)

// PRIMITIVES

/// General way to create HTML nodes. It is used to define all of the helper
/// functions in this library.
///
///     fn div(attributes: List(Attribute(msg)), children: List(Html(msg))) -> Html(msg) {
///       node("div", attributes, children)
///     }
///
/// You can use this to create custom nodes if you need to create something that
/// is not covered by the helper functions in this library.
pub fn node(
  tag: String,
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node(tag, attributes, children)
}

/// Just put plain text in the DOM. It will escape the string so that it appears
/// exactly as you specify.
///
///     text "Hello World!"
pub fn text(text: String) -> Html(msg) {
  virtual_dom.text(text)
}

// NESTING VIEWS

/// Transform the messages produced by some `Html`. In the following example,
/// we have `viewButton` that produces `()` messages, and we transform those values
/// into `Msg` values in `view`.
///
///     type Msg {
///       Left
///       Right
///     }
///
///     fn view(model: model) -> Html(Msg) {
///       div([], [
///         map(view_button("Left"), fn(_) { Left }),
///         map(view_button("Right"), fn(_) { Right })
///       ])
///     }
///
///     fn view_button(name: String) -> Html(Nil) {
///       button([on_click(Nil)], [text(name)])
///     }
///
/// If you are growing your project as recommended in [the official
/// guide](https://guide.elm-lang.org/), this should not come in handy in most
/// projects. Usually it is easier to just pass things in as arguments.
///
/// **Note:** Some folks have tried to use this to make “components” in their
/// projects, but they run into the fact that components are objects. Both are
/// local mutable state with methods. Elm is not an object-oriented language, so
/// you run into all sorts of friction if you try to use it like one. I definitely
/// recommend against going down that path! Instead, make the simplest function
/// possible and repeat.
pub fn map(element: Html(a), tagger: fn(a) -> msg) -> Html(msg) {
  virtual_dom.map(element, tagger)
}

// SECTIONS

/// Defines a section in a document.
pub fn section(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("section", attributes, children)
}

/// Defines a section that contains only navigation links.
pub fn nav(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("nav", attributes, children)
}

/// Defines self-contained content that could exist independently of the rest
/// of the content.
pub fn article(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("article", attributes, children)
}

/// Defines some content loosely related to the page content. If it is removed,
/// the remaining content still makes sense.
pub fn aside(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("aside", attributes, children)
}

///
pub fn h1(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("h1", attributes, children)
}

///
pub fn h2(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("h2", attributes, children)
}

///
pub fn h3(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("h3", attributes, children)
}

///
pub fn h4(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("h4", attributes, children)
}

///
pub fn h5(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("h5", attributes, children)
}

///
pub fn h6(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("h6", attributes, children)
}

/// Defines the header of a page or section. It often contains a logo, the
/// title of the web site, and a navigational table of content.
pub fn header(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("header", attributes, children)
}

/// Defines the footer for a page or section. It often contains a copyright
/// notice, some links to legal information, or addresses to give feedback.
pub fn footer(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("footer", attributes, children)
}

/// Defines a section containing contact information.
pub fn address(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("address", attributes, children)
}

/// Defines the main or important content in the document. There is only one
/// `main` element in the document.
pub fn main_(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("main", attributes, children)
}

// GROUPING CONTENT

/// Defines a portion that should be displayed as a paragraph.
pub fn p(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("p", attributes, children)
}

/// Represents a thematic break between paragraphs of a section or article or
/// any longer content.
pub fn hr(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("hr", attributes, children)
}

/// Indicates that its content is preformatted and that this format must be
/// preserved.
pub fn pre(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("pre", attributes, children)
}

/// Represents a content that is quoted from another source.
pub fn blockquote(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("blockquote", attributes, children)
}

/// Defines an ordered list of items.
pub fn ol(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("ol", attributes, children)
}

/// Defines an unordered list of items.
pub fn ul(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("ul", attributes, children)
}

/// Defines a item of an enumeration list.
pub fn li(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("li", attributes, children)
}

/// Defines a definition list, that is, a list of terms and their associated
/// definitions.
pub fn dl(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("dl", attributes, children)
}

/// Represents a term defined by the next `dd`.
pub fn dt(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("dt", attributes, children)
}

/// Represents the definition of the terms immediately listed before it.
pub fn dd(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("dd", attributes, children)
}

/// Represents a figure illustrated as part of the document.
pub fn figure(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("figure", attributes, children)
}

/// Represents the legend of a figure.
pub fn figcaption(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("figcaption", attributes, children)
}

/// Represents a generic container with no special meaning.
pub fn div(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("div", attributes, children)
}

// TEXT LEVEL SEMANTIC

/// Represents a hyperlink, linking to another resource.
pub fn a(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("a", attributes, children)
}

/// Represents emphasized text, like a stress accent.
pub fn em(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("em", attributes, children)
}

/// Represents especially important text.
pub fn strong(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("strong", attributes, children)
}

/// Represents a side comment, that is, text like a disclaimer or a
/// copyright, which is not essential to the comprehension of the document.
pub fn small(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("small", attributes, children)
}

/// Represents content that is no longer accurate or relevant.
pub fn s(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("s", attributes, children)
}

/// Represents the title of a work.
pub fn cite(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("cite", attributes, children)
}

/// Represents an inline quotation.
pub fn q(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("q", attributes, children)
}

/// Represents a term whose definition is contained in its nearest ancestor
/// content.
pub fn dfn(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("dfn", attributes, children)
}

/// Represents an abbreviation or an acronym; the expansion of the
/// abbreviation can be represented in the title attribute.
pub fn abbr(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("abbr", attributes, children)
}

/// Represents a date and time value; the machine-readable equivalent can be
/// represented in the datetime attribute.
pub fn time(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("time", attributes, children)
}

/// Represents computer code.
pub fn code(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("code", attributes, children)
}

/// Represents a variable. Specific cases where it should be used include an
/// actual mathematical expression or programming context, an identifier
/// representing a constant, a symbol identifying a physical quantity, a function
/// parameter, or a mere placeholder in prose.
pub fn var(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("var", attributes, children)
}

/// Represents the output of a program or a computer.
pub fn samp(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("samp", attributes, children)
}

/// Represents user input, often from the keyboard, but not necessarily; it
/// may represent other input, like transcribed voice commands.
pub fn kbd(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("kbd", attributes, children)
}

/// Represent a subscript.
pub fn sub(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("sub", attributes, children)
}

/// Represent a superscript.
pub fn sup(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("sup", attributes, children)
}

/// Represents some text in an alternate voice or mood, or at least of
/// different quality, such as a taxonomic designation, a technical term, an
/// idiomatic phrase, a thought, or a ship name.
pub fn i(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("i", attributes, children)
}

/// Represents a text which to which attention is drawn for utilitarian
/// purposes. It doesn't convey extra importance and doesn't imply an alternate
/// voice.
pub fn b(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("b", attributes, children)
}

/// Represents a non-textual annotation for which the conventional
/// presentation is underlining, such labeling the text as being misspelt or
/// labeling a proper name in Chinese text.
pub fn u(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("u", attributes, children)
}

/// Represents text highlighted for reference purposes, that is for its
/// relevance in another context.
pub fn mark(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("mark", attributes, children)
}

/// Represents content to be marked with ruby annotations, short runs of text
/// presented alongside the text. This is often used in conjunction with East Asian
/// language where the annotations act as a guide for pronunciation, like the
/// Japanese furigana.
pub fn ruby(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("ruby", attributes, children)
}

/// Represents the text of a ruby annotation.
pub fn rt(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("rt", attributes, children)
}

/// Represents parenthesis around a ruby annotation, used to display the
/// annotation in an alternate way by browsers not supporting the standard display
/// for annotations.
pub fn rp(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("rp", attributes, children)
}

/// Represents text that must be isolated from its surrounding for
/// bidirectional text formatting. It allows embedding a span of text with a
/// different, or unknown, directionality.
pub fn bdi(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("bdi", attributes, children)
}

/// Represents the directionality of its children, in order to explicitly
/// override the Unicode bidirectional algorithm.
pub fn bdo(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("bdo", attributes, children)
}

/// Represents text with no specific meaning. This has to be used when no other
/// text-semantic element conveys an adequate meaning, which, in this case, is
/// often brought by global attributes like `class`, `lang`, or `dir`.
pub fn span(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("span", attributes, children)
}

/// Represents a line break.
pub fn br(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("br", attributes, children)
}

/// Represents a line break opportunity, that is a suggested point for
/// wrapping text in order to improve readability of text split on several lines.
pub fn wbr(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("wbr", attributes, children)
}

// EDITS

/// Defines an addition to the document.
pub fn ins(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("ins", attributes, children)
}

/// Defines a removal from the document.
pub fn del(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("del", attributes, children)
}

// EMBEDDED CONTENT

/// Represents an image.
pub fn img(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("img", attributes, children)
}

/// Embedded an HTML document.
pub fn iframe(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("iframe", attributes, children)
}

/// Represents a integration point for an external, often non-HTML,
/// application or interactive content.
pub fn embed(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("embed", attributes, children)
}

/// Represents an external resource, which is treated as an image, an HTML
/// sub-document, or an external resource to be processed by a plug-in.
pub fn object(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("object", attributes, children)
}

/// Defines parameters for use by plug-ins invoked by `object` elements.
pub fn param(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("param", attributes, children)
}

/// Represents a video, the associated audio and captions, and controls.
pub fn video(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("video", attributes, children)
}

/// Represents a sound or audio stream.
pub fn audio(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("audio", attributes, children)
}

/// Allows authors to specify alternative media resources for media elements
/// like `video` or `audio`.
pub fn source(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("source", attributes, children)
}

/// Allows authors to specify timed text track for media elements like `video`
/// or `audio`.
pub fn track(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("track", attributes, children)
}

/// Represents a bitmap area for graphics rendering.
pub fn canvas(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("canvas", attributes, children)
}

/// Defines a mathematical formula.
pub fn math(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("math", attributes, children)
}

// TABULAR DATA

/// Represents data with more than one dimension.
pub fn table(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("table", attributes, children)
}

/// Represents the title of a table.
pub fn caption(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("caption", attributes, children)
}

/// Represents a set of one or more columns of a table.
pub fn colgroup(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("colgroup", attributes, children)
}

/// Represents a column of a table.
pub fn col(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("col", attributes, children)
}

/// Represents the block of rows that describes the concrete data of a table.
pub fn tbody(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("tbody", attributes, children)
}

/// Represents the block of rows that describes the column labels of a table.
pub fn thead(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("thead", attributes, children)
}

/// Represents the block of rows that describes the column summaries of a table.
pub fn tfoot(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("tfoot", attributes, children)
}

/// Represents a row of cells in a table.
pub fn tr(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("tr", attributes, children)
}

/// Represents a data cell in a table.
pub fn td(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("td", attributes, children)
}

/// Represents a header cell in a table.
pub fn th(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("th", attributes, children)
}

// FORMS

/// Represents a form, consisting of controls, that can be submitted to a
/// server for processing.
pub fn form(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("form", attributes, children)
}

/// Represents a set of controls.
pub fn fieldset(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("fieldset", attributes, children)
}

/// Represents the caption for a `fieldset`.
pub fn legend(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("legend", attributes, children)
}

/// Represents the caption of a form control.
pub fn label(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("label", attributes, children)
}

/// Represents a typed data field allowing the user to edit the data.
pub fn input(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("input", attributes, children)
}

/// Represents a button.
pub fn button(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("button", attributes, children)
}

/// Represents a control allowing selection among a set of options.
pub fn select(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("select", attributes, children)
}

/// Represents a set of predefined options for other controls.
pub fn datalist(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("datalist", attributes, children)
}

/// Represents a set of options, logically grouped.
pub fn optgroup(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("optgroup", attributes, children)
}

/// Represents an option in a `select` element or a suggestion of a `datalist`
/// element.
pub fn option(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("option", attributes, children)
}

/// Represents a multiline text edit control.
pub fn textarea(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("textarea", attributes, children)
}

/// Represents the result of a calculation.
pub fn output(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("output", attributes, children)
}

/// Represents the completion progress of a task.
pub fn progress(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("progress", attributes, children)
}

/// Represents a scalar measurement (or a fractional value), within a known
/// range.
pub fn meter(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("meter", attributes, children)
}

// INTERACTIVE ELEMENTS

/// Represents a widget from which the user can obtain additional information
/// or controls.
pub fn details(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("details", attributes, children)
}

/// Represents a summary, caption, or legend for a given `details`.
pub fn summary(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("summary", attributes, children)
}

/// Represents a command that the user can invoke.
pub fn menuitem(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("menuitem", attributes, children)
}

/// Represents a list of commands.
pub fn menu(
  attributes: List(Attribute(msg)),
  children: List(Html(msg)),
) -> Html(msg) {
  virtual_dom.node("menu", attributes, children)
}
