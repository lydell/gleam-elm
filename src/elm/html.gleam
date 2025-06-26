//// This file is organized roughly in order of popularity. The tags which you'd
//// expect to use frequently will be closer to the top.
////
//// # Primitives
//// @docs Html, Attribute, text, node, map
////
//// # Tags
////
//// ## Headers
//// @docs h1, h2, h3, h4, h5, h6
////
//// ## Grouping Content
//// @docs div, p, hr, pre, blockquote
////
//// ## Text
//// @docs span, a, code, em, strong, i, b, u, sub, sup, br
////
//// ## Lists
//// @docs ol, ul, li, dl, dt, dd
////
//// ## Embedded Content
//// @docs img, iframe, canvas, math
////
//// ## Inputs
//// @docs form, input, textarea, button, select, option
////
//// ## Sections
//// @docs section, nav, article, aside, header, footer, address, main_
////
//// ## Figures
//// @docs figure, figcaption
////
//// ## Tables
//// @docs table, caption, colgroup, col, tbody, thead, tfoot, tr, td, th
////
////
//// ## Less Common Elements
////
//// ### Less Common Inputs
//// @docs fieldset, legend, label, datalist, optgroup, output, progress, meter
////
//// ### Audio and Video
//// @docs audio, video, source, track
////
//// ### Embedded Objects
//// @docs embed, object, param
////
//// ### Text Edits
//// @docs ins, del
////
//// ### Semantic Text
//// @docs small, cite, dfn, abbr, time, var, samp, kbd, s, q
////
//// ### Less Common Text Tags
//// @docs mark, ruby, rt, rp, bdi, bdo, wbr
////
//// ## Interactive Elements
//// @docs details, summary, menuitem, menu

import elm/virtual_dom

// CORE TYPES

/// The core building block used to build up HTML. Here we create an `Html`
/// value with no attributes and one child:
///
///     hello : Html msg
///     hello =
///       div [] [ text "Hello!" ]
pub type Html(msg) =
  virtual_dom.Node(msg)

/// Set attributes on your `Html`. Learn more in the
/// [`Html.Attributes`](Html-Attributes) module.
pub type Attribute(msg) =
  virtual_dom.Attribute(msg)
