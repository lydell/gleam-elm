//// # URLs
//// @docs Url, Protocol, toString, fromString
////
//// # Percent-Encoding
//// @docs percentEncode, percentDecode

import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/string

// URL

/// In [the URI spec](https://tools.ietf.org/html/rfc3986), Tim Berners-Lee
/// says a URL looks like this:
///
/// ```
///   https://example.com:8042/over/there?name=ferret#nose
///   \___/   \______________/\_________/ \_________/ \__/
///     |            |            |            |        |
///   scheme     authority       path        query   fragment
/// ```
///
/// When you are creating a single-page app with [`Browser.application`][app], you
/// use the [`Url.Parser`](Url-Parser) module to turn a `Url` into even nicer data.
///
/// If you want to create your own URLs, check out the [`Url.Builder`](Url-Builder)
/// module as well!
///
/// [app]: /packages/elm/browser/latest/Browser#application
///
/// **Note:** This is a subset of all the full possibilities listed in the URI
/// spec. Specifically, it does not accept the `userinfo` segment you see in email
/// addresses like `tom@example.com`.
pub type Url {
  Url(
    protocol: Protocol,
    host: String,
    port_: Option(Int),
    path: String,
    query: Option(String),
    fragment: Option(String),
  )
}

/// Is the URL served over a secure connection or not?
pub type Protocol {
  Http
  Https
}

/// Attempt to break a URL up into [`Url`](#Url). This is useful in
/// single-page apps when you want to parse certain chunks of a URL to figure out
/// what to show on screen.
///
///     from_string("https://example.com:443")
///     // Some(
///     //   Url(
///     //     protocol: Https,
///     //     host: "example.com",
///     //     port_: Some(443),
///     //     path: "/",
///     //     query: None,
///     //     fragment: None,
///     //   )
///     // )
///
///     from_string("https://example.com/hats?q=top%20hat")
///     // Some(
///     //   Url(
///     //     protocol: Https,
///     //     host: "example.com",
///     //     port_: None,
///     //     path: "/hats",
///     //     query: Some("q=top%20hat"),
///     //     fragment: None,
///     //   )
///     // )
///
///    from_string("http://example.com/core/List/#map")
///    // Some(
///    //   Url(
///    //     protocol: Http,
///    //     host: "example.com",
///    //     port_: None,
///    //     path: "/core/List/",
///    //     query: None,
///    //     fragment: Some("map"),
///    //   )
///    // )
///
/// The conversion to segments can fail in some cases as well:
///
///     from_string("example.com:443")        == None  // no protocol
///     from_string("http://tom@example.com") == None  // userinfo disallowed
///     from_string("http://#cats")           == None  // no host
///
/// **Note:** This function does not use [`percentDecode`](#percentDecode) anything.
/// It just splits things up. [`Url.Parser`](Url-Parser) actually _needs_ the raw
/// `query` string to parse it properly. Otherwise it could get confused about `=`
/// and `&` characters!
pub fn from_string(str: String) -> Option(Url) {
  case str {
    "http://" <> rest -> chomp_after_protocol(Http, rest)
    "https://" <> rest -> chomp_after_protocol(Https, rest)
    _ -> None
  }
}

fn chomp_after_protocol(protocol: Protocol, str: String) -> Option(Url) {
  case str {
    "" -> None
    _ ->
      case string.split_once(str, on: "#") {
        Error(Nil) -> chomp_before_fragment(protocol, None, str)
        Ok(#(left, right)) -> chomp_before_fragment(protocol, Some(right), left)
      }
  }
}

fn chomp_before_fragment(
  protocol: Protocol,
  frag: Option(String),
  str: String,
) -> Option(Url) {
  case str {
    "" -> None
    _ ->
      case string.split_once(str, on: "?") {
        Error(Nil) -> chomp_before_query(protocol, None, frag, str)

        Ok(#(left, right)) ->
          chomp_before_query(protocol, Some(right), frag, left)
      }
  }
}

fn chomp_before_query(
  protocol: Protocol,
  params: Option(String),
  frag: Option(String),
  str: String,
) -> Option(Url) {
  case str {
    "" -> None
    _ ->
      case string.split_once(str, on: "/") {
        Error(Nil) -> chomp_before_path(protocol, "/", params, frag, str)

        Ok(#(left, right)) ->
          chomp_before_path(protocol, "/" <> right, params, frag, left)
      }
  }
}

fn chomp_before_path(
  protocol: Protocol,
  path: String,
  params: Option(String),
  frag: Option(String),
  str: String,
) -> Option(Url) {
  case string.is_empty(str) || string.contains(str, "@") {
    True -> None
    False ->
      case string.split_once(str, on: ":") {
        Error(Nil) ->
          Some(Url(
            protocol:,
            host: str,
            port_: None,
            path:,
            query: params,
            fragment: frag,
          ))
        Ok(#(left, right)) ->
          case int.parse(right) {
            Error(Nil) -> None
            Ok(port_) ->
              Some(Url(
                protocol:,
                host: left,
                port_: Some(port_),
                path:,
                query: params,
                fragment: frag,
              ))
          }
      }
  }
}

/// Turn a [`Url`](#Url) into a `String`.
pub fn to_string(url: Url) -> String {
  let http = case url.protocol {
    Http -> "http://"
    Https -> "https://"
  }
  add_port(url.port_, http <> url.host)
  <> url.path
  |> add_prefixed("?", url.query)
  |> add_prefixed("#", url.fragment)
}

fn add_port(maybe_port: Option(Int), starter: String) -> String {
  case maybe_port {
    None -> starter
    Some(port_) -> starter <> ":" <> int.to_string(port_)
  }
}

fn add_prefixed(
  starter: String,
  prefix: String,
  maybe_segment: Option(String),
) -> String {
  case maybe_segment {
    None -> starter

    Some(segment) -> starter <> prefix <> segment
  }
}

// PERCENT ENCODING

/// **Use [Url.Builder](Url-Builder) instead!** Functions like `absolute`,
/// `relative`, and `crossOrigin` already do this automatically! `percentEncode`
/// is only available so that extremely custom cases are possible, if needed.
///
/// Percent-encoding is how [the official URI spec][uri] “escapes” special
/// characters. You can still represent a `?` even though it is reserved for
/// queries.
///
/// This function exists in case you want to do something extra custom. Here are
/// some examples:
///
///     // standard ASCII encoding
///     percent_encode("hat")   == "hat"
///     percent_encode("to be") == "to%20be"
///     percent_encode("99%")   == "99%25"
///
///     // non-standard, but widely accepted, UTF-8 encoding
///     percent_encode("$") == "%24"
///     percent_encode("¢") == "%C2%A2"
///     percent_encode("€") == "%E2%82%AC"
///
/// This is the same behavior as JavaScript's [`encodeURIComponent`][js] function,
/// and the rules are described in more detail officially [here][s2] and with some
/// notes about Unicode [here][wiki].
///
/// [js]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
/// [uri]: https://tools.ietf.org/html/rfc3986
/// [s2]: https://tools.ietf.org/html/rfc3986#section-2.1
/// [wiki]: https://en.wikipedia.org/wiki/Percent-encoding
@external(javascript, "./url.ffi.mjs", "_Url_percentEncode")
pub fn percent_encode(str: String) -> String

/// **Use [Url.Parser](Url-Parser) instead!** It will decode query
/// parameters appropriately already! `percentDecode` is only available so that
/// extremely custom cases are possible, if needed.
///
/// Check out the `percentEncode` function to learn about percent-encoding.
/// This function does the opposite! Here are the reverse examples:
///
///     // ASCII
///     percent_decode("hat")       == Some("hat")
///     percent_decode("to%20be")   == Some("to be")
///     percent_decode("99%25")     == Some("99%")
///
///     // UTF-8
///     percent_decode("%24")       == Some("$")
///     percent_decode("%C2%A2")    == Some("¢")
///     percent_decode("%E2%82%AC") == Some("€")
///
/// Why is it a `Maybe` though? Well, these strings come from strangers on the
/// internet as a bunch of bits and may have encoding problems. For example:
///
///     percent_decode("%")   == None  // not followed by two hex digits
///     percent_decode("%XY") == None  // not followed by two HEX digits
///     percent_decode("%C2") == None  // half of the "¢" encoding "%C2%A2"
///
/// This is the same behavior as JavaScript's [`decodeURIComponent`][js] function.
///
/// [js]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURIComponent
@external(javascript, "./url.ffi.mjs", "_Url_percentDecode")
pub fn percent_decode(str: String) -> Option(String)
