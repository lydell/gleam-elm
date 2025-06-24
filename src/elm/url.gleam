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
///     fromString "https://example.com:443"
///     -- Just
///     --   { protocol = Https
///     --   , host = "example.com"
///     --   , port_ = Just 443
///     --   , path = "/"
///     --   , query = Nothing
///     --   , fragment = Nothing
///     --   }
///
///     fromString "https://example.com/hats?q=top%20hat"
///     -- Just
///     --   { protocol = Https
///     --   , host = "example.com"
///     --   , port_ = Nothing
///     --   , path = "/hats"
///     --   , query = Just "q=top%20hat"
///     --   , fragment = Nothing
///     --   }
///
///    fromString "http://example.com/core/List/#map"
///    -- Just
///    --   { protocol = Http
///    --   , host = "example.com"
///    --   , port_ = Nothing
///    --   , path = "/core/List/"
///    --   , query = Nothing
///    --   , fragment = Just "map"
///    --   }
///
/// The conversion to segments can fail in some cases as well:
///
///     fromString "example.com:443"        == Nothing  -- no protocol
///     fromString "http://tom@example.com" == Nothing  -- userinfo disallowed
///     fromString "http://#cats"           == Nothing  -- no host
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
        Ok(#(left, right)) -> chomp_before_fragment(protocol, Some(left), right)
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
          chomp_before_query(protocol, Some(left), frag, right)
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
          chomp_before_path(protocol, left, params, frag, right)
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
