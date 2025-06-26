import elm/json/encode
import gleam/list

pub type Decoder(a)

// PRIMITIVES

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

/// Decode a JSON boolean into an Elm `Bool`.
///
///     decodeString bool "true"              == Ok True
///     decodeString bool "42"                == Err ...
///     decodeString bool "3.14"              == Err ...
///     decodeString bool "\"hello\""         == Err ...
///     decodeString bool "{ \"hello\": 42 }" == Err ...
@external(javascript, "../json.ffi.mjs", "_Json_decodeBool")
pub fn bool() -> Decoder(Bool)

/// Decode a JSON number into an Elm `Int`.
///
///     decodeString int "true"              == Err ...
///     decodeString int "42"                == Ok 42
///     decodeString int "3.14"              == Err ...
///     decodeString int "\"hello\""         == Err ...
///     decodeString int "{ \"hello\": 42 }" == Err ...
@external(javascript, "../json.ffi.mjs", "_Json_decodeInt")
pub fn int() -> Decoder(Int)

/// Decode a JSON number into an Elm `Float`.
///
///     decodeString float "true"              == Err ..
///     decodeString float "42"                == Ok 42
///     decodeString float "3.14"              == Ok 3.14
///     decodeString float "\"hello\""         == Err ...
///     decodeString float "{ \"hello\": 42 }" == Err ...
@external(javascript, "../json.ffi.mjs", "_Json_decodeFloat")
pub fn float() -> Decoder(Float)

// DATA STRUCTURES (TODO)

// OBJECT PRIMITIVES

/// Decode a JSON object, requiring a particular field.
///
///     decodeString (field "x" int) "{ \"x\": 3 }"            == Ok 3
///     decodeString (field "x" int) "{ \"x\": 3, \"y\": 4 }"  == Ok 3
///     decodeString (field "x" int) "{ \"x\": true }"         == Err ...
///     decodeString (field "x" int) "{ \"y\": 4 }"            == Err ...
///
///     decodeString (field "name" string) "{ \"name\": \"tom\" }" == Ok "tom"
///
/// The object *can* have other fields. Lots of them! The only thing this decoder
/// cares about is if `x` is present and that the value there is an `Int`.
///
/// Check out [`map2`](#map2) to see how to decode multiple fields!
@external(javascript, "../json.ffi.mjs", "_Json_decodeField")
pub fn field(name: String, decoder: Decoder(a)) -> Decoder(a)

/// Decode a nested JSON object, requiring certain fields.
///
///     json = """{ "person": { "name": "tom", "age": 42 } }"""
///
///     decodeString (at ["person", "name"] string) json  == Ok "tom"
///     decodeString (at ["person", "age" ] int   ) json  == Ok 42
///
/// This is really just a shorthand for saying things like:
///
///     field "person" (field "name" string) == at ["person","name"] string
pub fn at(fields: List(String), decoder: Decoder(a)) -> Decoder(a) {
  list.fold(fields, decoder, fn(acc, field_name) { field(field_name, acc) })
}

/// Decode a JSON array, requiring a particular index.
///
///     json = """[ "alice", "bob", "chuck" ]"""
///
///     decodeString (index 0 string) json  == Ok "alice"
///     decodeString (index 1 string) json  == Ok "bob"
///     decodeString (index 2 string) json  == Ok "chuck"
///     decodeString (index 3 string) json  == Err ...
@external(javascript, "../json.ffi.mjs", "_Json_decodeIndex")
pub fn index(index: Int, decoder: Decoder(a)) -> Decoder(a)

// WEIRD STRUCTURE (TODO)

// MAPPING (TODO: map2–map8)

/// Transform a decoder. Maybe you just want to know the length of a string:
///
///     import String
///
///     stringLength : Decoder Int
///     stringLength =
///       map String.length string
///
/// It is often helpful to use `map` with `oneOf`, like when defining `nullable`:
///
///     nullable : Decoder a -> Decoder (Maybe a)
///     nullable decoder =
///       oneOf
///         [ null Nothing
///         , map Just decoder
///         ]
@external(javascript, "../json.ffi.mjs", "_Json_map")
pub fn map(tagger: fn(a) -> value, decoder: Decoder(a)) -> Decoder(value)

// RUN DECODERS (TODO)

// FANCY PRIMITIVES (TODO: andThen etc)

/// Ignore the JSON and produce a certain Elm value.
///
///     decodeString (succeed 42) "true"    == Ok 42
///     decodeString (succeed 42) "[1,2,3]" == Ok 42
///     decodeString (succeed 42) "hello"   == Err ... -- this is not a valid JSON string
///
/// This is handy when used with `oneOf` or `andThen`.
@external(javascript, "../json.ffi.mjs", "_Json_succeed")
pub fn succeed(value: a) -> Decoder(a)

/// Ignore the JSON and make the decoder fail. This is handy when used with
/// `oneOf` or `andThen` where you want to give a custom error message in some
/// case.
///
/// See the [`andThen`](#andThen) docs for an example.
@external(javascript, "../json.ffi.mjs", "_Json_fail")
pub fn fail(message: String) -> Decoder(a)
