//// This module helps you set up an Elm `Program` with functions like
//// [`sandbox`](#sandbox) and [`document`](#document).
////

import elm/browser/navigation
import elm/html.{type Html}
import elm/json/decode.{type Decoder}
import elm/platform.{type Program}
import elm/platform/cmd.{type Cmd}
import elm/platform/sub.{type Sub}
import elm/url.{type Url}

// SANDBOX

/// Create a “sandboxed” program that cannot communicate with the outside
/// world.
///
/// This is great for learning the basics of [The Elm Architecture][tea]. You can
/// see sandboxes in action in the following examples:
///
///   - [Buttons](https://guide.elm-lang.org/architecture/buttons.html)
///   - [Text Fields](https://guide.elm-lang.org/architecture/text_fields.html)
///   - [Forms](https://guide.elm-lang.org/architecture/forms.html)
///
/// Those are nice, but **I very highly recommend reading [this guide][guide]
/// straight through** to really learn how Elm works. Understanding the
/// fundamentals actually pays off in this language!
///
/// [tea]: https://guide.elm-lang.org/architecture/
/// [guide]: https://guide.elm-lang.org/
pub fn sandbox(
  init init: model,
  view view: fn(model) -> Html(msg),
  update update: fn(msg, model) -> model,
) -> Program(Nil, model, msg) {
  element(
    flags_decoder: decode.succeed(Nil),
    init: fn(_) { #(init, cmd.none()) },
    view: view,
    update: fn(msg, model) { #(update(msg, model), cmd.none()) },
    subscriptions: fn(_) { sub.none() },
    effect_managers: [],
  )
}

// ELEMENT

/// Create an HTML element managed by Elm. The resulting elements are easy to
/// embed in larger JavaScript projects, and lots of companies that use Elm
/// started with this approach! Try it out on something small. If it works, great,
/// do more! If not, revert, no big deal.
///
/// Unlike a [`sandbox`](#sandbox), an `element` can talk to the outside world in
/// a couple ways:
///
///   - `Cmd` &mdash; you can “command” the Elm runtime to do stuff, like HTTP.
///   - `Sub` &mdash; you can “subscribe” to event sources, like clock ticks.
///   - `flags` &mdash; JavaScript can pass in data when starting the Elm program
///   - `ports` &mdash; set up a client-server relationship with JavaScript
///
/// As you read [the guide][guide] you will run into a bunch of examples of `element`
/// in [this section][fx]. You can learn more about flags and ports in [the interop
/// section][interop].
///
/// [guide]: https://guide.elm-lang.org/
/// [fx]: https://guide.elm-lang.org/effects/
/// [interop]: https://guide.elm-lang.org/interop/
@external(javascript, "./browser.ffi.mjs", "_Browser_element")
pub fn element(
  flags_decoder flags_decoder: Decoder(flags),
  init init: fn(flags) -> #(model, Cmd(msg)),
  view view: fn(model) -> Html(msg),
  update update: fn(msg, model) -> #(model, Cmd(msg)),
  subscriptions subscriptions: fn(model) -> Sub(msg),
  effect_managers effect_managers: List(platform.EffectManager),
) -> Program(flags, model, msg)

// DOCUMENT

/// Create an HTML document managed by Elm. This expands upon what `element`
/// can do in that `view` now gives you control over the `<title>` and `<body>`.
@external(javascript, "./browser.ffi.mjs", "_Browser_document")
pub fn document(
  flags_decoder flags_decoder: Decoder(flags),
  init init: fn(flags) -> #(model, Cmd(msg)),
  view view: fn(model) -> Document(msg),
  update update: fn(msg, model) -> #(model, Cmd(msg)),
  subscriptions subscriptions: fn(model) -> Sub(msg),
  effect_managers effect_managers: List(platform.EffectManager),
) -> Program(flags, model, msg)

/// This data specifies the `<title>` and all of the nodes that should go in
/// the `<body>`. This means you can update the title as your application changes.
/// Maybe your "single-page app" navigates to a "different page", maybe a calendar
/// app shows an accurate date in the title, etc.
///
/// > **Note about CSS:** This looks similar to an `<html>` document, but this is
/// > not the place to manage CSS assets. If you want to work with CSS, there are
/// > a couple ways:
/// >
/// > 1.  Packages like [`rtfeldman/elm-css`][elm-css] give all of the features
/// >     of CSS without any CSS files. You can add all the styles you need in your
/// >     `view` function, and there is no need to worry about class names matching.
/// >
/// > 2.  Compile your Elm code to JavaScript with `elm make --output=elm.js` and
/// >     then make your own HTML file that loads `elm.js` and the CSS file you want.
/// >     With this approach, it does not matter where the CSS comes from. Write it
/// >     by hand. Generate it. Whatever you want to do.
/// >
/// > 3.  If you need to change `<link>` tags dynamically, you can send messages
/// >     out a port to do it in JavaScript.
/// >
/// > The bigger point here is that loading assets involves touching the `<head>`
/// > as an implementation detail of browsers, but that does not mean it should be
/// > the responsibility of the `view` function in Elm. So we do it differently!
///
/// [elm-css]: /packages/rtfeldman/elm-css/latest/
pub type Document(msg) {
  Document(title: String, body: List(Html(msg)))
}

// APPLICATION

/// Create an application that manages [`Url`][url] changes.
///
/// **When the application starts**, `init` gets the initial `Url`. You can show
/// different things depending on the `Url`!
///
/// **When someone clicks a link**, like `<a href="/home">Home</a>`, it always goes
/// through `onUrlRequest`. The resulting message goes to your `update` function,
/// giving you a chance to save scroll position or persist data before changing
/// the URL yourself with [`pushUrl`][bnp] or [`load`][bnl]. More info on this in
/// the [`UrlRequest`](#UrlRequest) docs!
///
/// **When the URL changes**, the new `Url` goes through `onUrlChange`. The
/// resulting message goes to `update` where you can decide what to show next.
///
/// Applications always use the [`Browser.Navigation`][bn] module for precise
/// control over `Url` changes.
///
/// **More Info:** Here are some example usages of `application` programs:
///
///   - [RealWorld example app](https://github.com/rtfeldman/elm-spa-example)
///   - [Elm’s package website](https://github.com/elm/package.elm-lang.org)
///
/// These are quite advanced Elm programs, so be sure to go through [the guide][g]
/// first to get a solid conceptual foundation before diving in! If you start
/// reading a calculus book from page 314, it might seem confusing. Same here!
///
/// **Note:** Can an [`element`](#element) manage the URL too? Read [this]!
///
/// [g]: https://guide.elm-lang.org/
/// [bn]: Browser-Navigation
/// [bnp]: Browser-Navigation#pushUrl
/// [bnl]: Browser-Navigation#load
/// [url]: /packages/elm/url/latest/Url#Url
/// [this]: https://github.com/elm/browser/blob/1.0.2/notes/navigation-in-elements.md
@external(javascript, "./browser.ffi.mjs", "_Browser_application")
pub fn application(
  flags_decoder flags_decoder: Decoder(flags),
  init init: fn(flags, Url, navigation.Key) -> #(model, Cmd(msg)),
  view view: fn(model) -> Document(msg),
  update update: fn(msg, model) -> #(model, Cmd(msg)),
  subscriptions subscriptions: fn(model) -> Sub(msg),
  on_url_request on_url_request: fn(UrlRequest) -> msg,
  on_url_change on_url_change: fn(Url) -> msg,
  effect_managers effect_managers: List(platform.EffectManager),
) -> Program(flags, model, msg)

/// All links in an [`application`](#application) create a `UrlRequest`. So
/// when you click `<a href="/home">Home</a>`, it does not just navigate! It
/// notifies `onUrlRequest` that the user wants to change the `Url`.
///
///
/// ### `Internal` vs `External`
///
/// Imagine we are browsing `https://example.com`. An `Internal` link would be
/// like:
///
///   - `settings#privacy`
///   - `/home`
///   - `https://example.com/home`
///   - `//example.com/home`
///
/// All of these links exist under the `https://example.com` domain. An `External`
/// link would be like:
///
///   - `https://elm-lang.org/examples`
///   - `https://other.example.com/home`
///   - `http://example.com/home`
///
/// Anything that changes the domain. Notice that changing the protocol from
/// `https` to `http` is considered a different domain! (And vice versa!)
///
///
/// ### Purpose
///
/// Having a `UrlRequest` requires a case in your `update` like this:
///
///     import elm/browser
///     import elm/browser/navigation as nav
///     import elm/url
///
///     type Msg {
///       ClickedLink(browser.UrlRequest)
///     }
///
///     fn update(msg: Msg, model: Model) -> #(Model, platform.Cmd(msg)) {
///       case msg {
///         ClickedLink(url_request) ->
///           case url_request {
///             browser.Internal(url) ->
///               #(model, nav.push_url(model.key, url.to_string(url)))
///             browser.External(url) ->
///               #(model, nav.load(url))
///           }
///       }
///     }
///
/// This is useful because it gives you a chance to customize the behavior in each
/// case. Maybe on some `Internal` links you save the scroll position with
/// [`Browser.Dom.getViewport`](Browser-Dom#getViewport) so you can restore it
/// later. Maybe on `External` links you persist parts of the `Model` on your
/// servers before leaving. Whatever you need to do!
///
/// **Note:** Knowing the scroll position is not enough to restore it! What if the
/// browser dimensions change? The scroll position will not correlate with
/// &ldquo;what was on screen&rdquo; anymore. So it may be better to remember
/// &ldquo;what was on screen&rdquo; and recreate the position based on that. For
/// example, in a Wikipedia article, remember the header that they were looking at
/// most recently. [`Browser.Dom.getElement`](Browser-Dom#getElement) is designed
/// for figuring that out!
pub type UrlRequest {
  Internal(Url)
  External(String)
}
