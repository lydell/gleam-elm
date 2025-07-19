//// This module helps you manage the browser's URL yourself. This is the
//// crucial trick when using `browser.application`.
////
//// The most important function is `push_url` which changes the
//// address bar _without_ starting a page load.
////
////
//// ## What is a page load?
////
//// 1.  Request a new HTML document. The page goes blank.
//// 2.  As the HTML loads, request any `<script>` or `<link>` resources.
//// 3.  A `<script>` may mutate the document, so these tags block rendering.
//// 4.  When _all_ of the assets are loaded, actually render the page.
////
//// That means the page will go blank for at least two round-trips to the servers!
//// You may have 90% of the data you need and be blocked on a font that is taking
//// a long time. Still blank!
////
////
//// ## How does `push_url` help?
////
//// The `push_url` function changes the URL, but lets you keep the current HTML.
//// This means the page _never_ goes blank. Instead of making two round-trips to
//// the server, you load whatever assets you want from within Gleam. Maybe you do
//// not need any round-trips! Meanwhile, you retain full control over the UI, so
//// you can show a loading bar, show information as it loads, etc. Whatever you
//// want!

import elm/platform/cmd.{type Cmd}

// WITHIN PAGE

/// A navigation `Key` is needed to create navigation commands that change the
/// URL. That includes `push_url`, `replace_url`, `back`, and `forward`.
///
/// You only get access to a `Key` when you create your program with
/// `browser.application`, guaranteeing that your program is
/// equipped to detect these URL changes. If `Key` values were available in other
/// kinds of programs, unsuspecting programmers would be sure to run into some
/// annoying bugs and learn a bunch of techniques the hard way!
///
pub type Key

/// Change the URL, but do not trigger a page load.
///
/// This will add a new entry to the browser history.
///
/// Check out the `elm/url` package for help building URLs. The
/// `url_builder.absolute` and `url_builder.relative` functions can
/// be particularly handy!
///
/// **Note:** If the user has gone `back` a few pages, there will be "future
/// pages" that the user can go `forward` to. Adding a new URL in that
/// scenario will clear out any future pages. It is like going back in time and
/// making a different choice.
///
@external(javascript, "../browser.ffi.mjs", "_Browser_pushUrl")
pub fn push_url(key: Key, url: String) -> Cmd(msg)

/// Change the URL, but do not trigger a page load.
///
/// This _will not_ add a new entry to the browser history.
///
/// This can be useful if you have search box and you want the `?search=hats` in
/// the URL to match without adding a history entry for every single key stroke.
/// Imagine how annoying it would be to click `back` thirty times and still be on
/// the same page!
///
/// **Note:** Browsers may rate-limit this function by throwing an exception. The
/// discussion [here](https://bugs.webkit.org/show_bug.cgi?id=156115) suggests
/// that the limit is 100 calls per 30 second interval in Safari in 2016. It also
/// suggests techniques for people changing the URL based on scroll position.
///
@external(javascript, "../browser.ffi.mjs", "_Browser_replaceUrl")
pub fn replace_url(key: Key, url: String) -> Cmd(msg)

/// Go back some number of pages. So `back(key, 1)` goes back one page, and
/// `back(key, 2)` goes back two pages.
///
/// **Note:** You only manage the browser history that _you_ created. Think of this
/// library as letting you have access to a small part of the overall history. So
/// if you go back farther than the history you own, you will just go back to some
/// other website!
pub fn back(key: Key, n: Int) -> Cmd(msg) {
  forward(key, -n)
}

/// Go forward some number of pages. So `forward(key, 1)` goes forward one page,
/// and `forward(key, 2)` goes forward two pages. If there are no more pages in
/// the future, this will do nothing.
///
/// **Note:** You only manage the browser history that _you_ created. Think of this
/// library as letting you have access to a small part of the overall history. So
/// if you go forward farther than the history you own, the user will end up on
/// whatever website they visited next!
@external(javascript, "../browser.ffi.mjs", "_Browser_go")
pub fn forward(key: Key, n: Int) -> Cmd(msg)

// EXTERNAL PAGES

/// Leave the current page and load the given URL. **This always results in a
/// page load**, even if the provided URL is the same as the current one.
///
///     fn goto_elm_website() -> Cmd(msg) {
///         load("https://elm-lang.org")
///     }
///
/// Check out the `elm/url` package for help building URLs. The
/// `url.absolute` and `url.relative` functions can be particularly
/// handy!
@external(javascript, "../browser.ffi.mjs", "_Browser_load")
pub fn load(url: String) -> Cmd(msg)

/// Reload the current page. **This always results in a page load!**
/// This may grab resources from the browser cache, so use
/// `reload_and_skip_cache` if you want to be sure that you are not loading
/// any cached resources.
pub fn reload() -> Cmd(msg) {
  reload_impl(False)
}

/// Reload the current page without using the browser cache. **This always
/// results in a page load!** It is more common to want `reload`.
pub fn reload_and_skip_cache() -> Cmd(msg) {
  reload_impl(True)
}

@external(javascript, "../browser.ffi.mjs", "_Browser_reload")
fn reload_impl(skip_cache: Bool) -> Cmd(msg)
