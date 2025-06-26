/// Represents a JavaScript value.
pub type Value

/// Turn a `String` into a JSON string.
/// 
///     import Json.Encode exposing (encode, string)
/// 
///     -- encode 0 (string "")      == "\"\""
///     -- encode 0 (string "abc")   == "\"abc\""
///     -- encode 0 (string "hello") == "\"hello\""
@external(javascript, "../json.ffi.mjs", "_Json_wrap")
pub fn string(value: string) -> Value

/// Turn an `Int` into a JSON number.
/// 
///     import Json.Encode exposing (encode, int)
/// 
///     -- encode 0 (int 42) == "42"
///     -- encode 0 (int -7) == "-7"
///     -- encode 0 (int 0)  == "0"
@external(javascript, "../json.ffi.mjs", "_Json_wrap")
pub fn int(value: Int) -> Value

/// Turn a `Bool` into a JSON boolean.
/// 
///     import Json.Encode exposing (encode, bool)
/// 
///     -- encode 0 (bool True)  == "true"
///     -- encode 0 (bool False) == "false"
@external(javascript, "../json.ffi.mjs", "_Json_wrap")
pub fn bool(value: Bool) -> Value
