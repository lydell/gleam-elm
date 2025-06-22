import elm/json/encode

pub type Decoder(a)

/// Represents a JavaScript value.
pub type Value =
  encode.Value

/// Decode a JSON string into an Elm `String`.
///
///    decodeString string "true"              == Err ...
///    decodeString string "42"                == Err ...
///    decodeString string "3.14"              == Err ...
///    decodeString string "\"hello\""         == Ok "hello"
///    decodeString string "{ \"hello\": 42 }" == Err ...
@external(javascript, "../json.ffi.mjs", "_Json_decodeString")
pub fn string() -> Decoder(String)

@external(javascript, "../json.ffi.mjs", "_Json_succeed")
pub fn succeed(value: a) -> Decoder(a)
