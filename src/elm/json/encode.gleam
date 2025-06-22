/// Represents a JavaScript value.
pub type Value

/// Turn an `Int` into a JSON number.
/// 
///     import Json.Encode exposing (encode, int)
/// 
///     -- encode 0 (int 42) == "42"
///     -- encode 0 (int -7) == "-7"
///     -- encode 0 (int 0)  == "0"
@external(javascript, "../json.ffi.mjs", "_Json_wrap")
pub fn int(value: Int) -> Value
