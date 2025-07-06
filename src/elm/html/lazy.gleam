//// Since all Elm functions are pure we have a guarantee that the same input
//// will always result in the same output. This module gives us tools to be lazy
//// about building `Html` that utilize this fact.
////
//// Rather than immediately applying functions to their arguments, the `lazy`
//// functions just bundle the function and arguments up for later. When diffing
//// the old and new virtual DOM, it checks to see if all the arguments are equal
//// by reference. If so, it skips calling the function!
////
//// This is a really cheap test and often makes things a lot faster, but definitely
//// benchmark to be sure!

import elm/html.{type Html}

/// A performance optimization that delays the building of virtual DOM nodes.
///
/// Calling `(view model)` will definitely build some virtual DOM, perhaps a lot of
/// it. Calling `(lazy view model)` delays the call until later. During diffing, we
/// can check to see if `model` is referentially equal to the previous value used,
/// and if so, we just stop. No need to build up the tree structure and diff it,
/// we know if the input to `view` is the same, the output must be the same!
@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy")
pub fn lazy(view: fn(a) -> Html(msg), a: a) -> Html(msg)

/// Same as `lazy` but checks on two arguments.
@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy2")
pub fn lazy2(view: fn(a, b) -> Html(msg), a: a, b: b) -> Html(msg)

/// Same as `lazy` but checks on three arguments.
@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy3")
pub fn lazy3(view: fn(a, b, c) -> Html(msg), a: a, b: b, c: c) -> Html(msg)

/// Same as `lazy` but checks on four arguments.
@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy4")
pub fn lazy4(
  view: fn(a, b, c, d) -> Html(msg),
  a: a,
  b: b,
  c: c,
  d: d,
) -> Html(msg)

/// Same as `lazy` but checks on five arguments.
@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy5")
pub fn lazy5(
  view: fn(a, b, c, d, e) -> Html(msg),
  a: a,
  b: b,
  c: c,
  d: d,
  e: e,
) -> Html(msg)

/// Same as `lazy` but checks on six arguments.
@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy6")
pub fn lazy6(
  view: fn(a, b, c, d, e, f) -> Html(msg),
  a: a,
  b: b,
  c: c,
  d: d,
  e: e,
  f: f,
) -> Html(msg)

/// Same as `lazy` but checks on seven arguments.
@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy7")
pub fn lazy7(
  view: fn(a, b, c, d, e, f, g) -> Html(msg),
  a: a,
  b: b,
  c: c,
  d: d,
  e: e,
  f: f,
  g: g,
) -> Html(msg)

/// Same as `lazy` but checks on eight arguments.
@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_lazy8")
pub fn lazy8(
  view: fn(a, b, c, d, e, f, g, h) -> Html(msg),
  a: a,
  b: b,
  c: c,
  d: d,
  e: e,
  f: f,
  g: g,
  h: h,
) -> Html(msg)
