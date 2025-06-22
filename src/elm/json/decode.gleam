import elm/json/encode

pub type Decoder(a)

/// Represents a JavaScript value.
pub type Value =
  encode.Value

@external(javascript, "../json.ffi.mjs", "_Json_succeed")
pub fn succeed(value: a) -> Decoder(a)
