/// Calculate the logarithm of a number with a given base.
/// 
///     logBase 10 100 == 2
///     logBase 2 256 == 8
@external(javascript, "./basics.ffi.mjs", "_Basics_logBase")
pub fn log_base(base: Float, number: Float) -> Float

/// A value that can never happen! For context:
/// 
///   - The boolean type `Bool` has two values: `True` and `False`
///   - The unit type `()` has one value: `()`
///   - The never type `Never` has no values!
/// 
/// You may see it in the wild in `Html Never` which means this HTML will never
/// produce any messages. You would need to write an event handler like
/// `onClick ??? : Attribute Never` but how can we fill in the question marks?!
/// So there cannot be any event handlers on that HTML.
/// 
/// You may also see this used with tasks that never fail, like `Task Never ()`.
/// 
/// The `Never` type is useful for restricting *arguments* to a function. Maybe my
/// API can only accept HTML without event handlers, so I require `Html Never` and
/// users can give `Html msg` and everything will go fine. Generally speaking, you
/// do not want `Never` in your return types though.
pub type Never

/// A function that can never be called. Seems extremely pointless, but it
/// *can* come in handy. Imagine you have some HTML that should never produce any
/// messages. And say you want to use it in some other HTML that *does* produce
/// messages. You could say:
/// 
///     import Html exposing (..)
/// 
///     embedHtml : Html Never -> Html msg
///     embedHtml staticStuff =
///       div []
///         [ text "hello"
///         , Html.map never staticStuff
///         ]
/// 
/// So the `never` function is basically telling the type system, make sure no one
/// ever calls me!
pub fn never(nvr: Never) -> a {
  never(nvr)
}
