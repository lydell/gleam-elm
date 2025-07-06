//// Library for turning Elm values into Json values.

import elm/array.{type Array}
import gleam/dict.{type Dict}
import gleam/list
import gleam/set.{type Set}

// ENCODING

/// Represents a JavaScript value.
pub type Value

/// Convert a `Value` into a prettified string. The first argument specifies
/// the amount of indentation in the resulting string.
///
///     import Json.Encode as Encode
///
///     tom : Encode.Value
///     tom =
///         Encode.object
///             [ ( "name", Encode.string "Tom" )
///             , ( "age", Encode.int 42 )
///             ]
///
///     compact =
///         Encode.encode 0 tom
///
///     -- {"name":"Tom","age":42}
///     readable =
///         Encode.encode 4 tom
///
///     -- {
///     --     "name": "Tom",
///     --     "age": 42
///     -- }
@external(javascript, "../json.ffi.mjs", "_Json_encode")
pub fn encode(value: Value, indent: Int) -> String

// PRIMITIVES

/// Turn a `String` into a JSON string.
///
///     import Json.Encode exposing (encode, string)
///
///     -- encode 0 (string "")      == "\"\""
///     -- encode 0 (string "abc")   == "\"abc\""
///     -- encode 0 (string "hello") == "\"hello\""
@external(javascript, "../json.ffi.mjs", "_Json_wrap")
pub fn string(value: String) -> Value

/// Turn an `Int` into a JSON number.
///
///     import Json.Encode exposing (encode, int)
///
///     -- encode 0 (int 42) == "42"
///     -- encode 0 (int -7) == "-7"
///     -- encode 0 (int 0)  == "0"
@external(javascript, "../json.ffi.mjs", "_Json_wrap")
pub fn int(value: Int) -> Value

/// Turn a `Float` into a JSON number.
///
///     import Json.Encode exposing (encode, float)
///
///     -- encode 0 (float 3.14)     == "3.14"
///     -- encode 0 (float 1.618)    == "1.618"
///     -- encode 0 (float -42)      == "-42"
///     -- encode 0 (float NaN)      == "null"
///     -- encode 0 (float Infinity) == "null"
///
/// **Note:** Floating point numbers are defined in the [IEEE 754 standard][ieee]
/// which is hardcoded into almost all CPUs. This standard allows `Infinity` and
/// `NaN`. [The JSON spec][json] does not include these values, so we encode them
/// both as `null`.
///
/// [ieee]: https://en.wikipedia.org/wiki/IEEE_754
/// [json]: https://www.json.org/
@external(javascript, "../json.ffi.mjs", "_Json_wrap")
pub fn float(value: Float) -> Value

/// Turn a `Bool` into a JSON boolean.
///
///     import Json.Encode exposing (bool, encode)
///
///     -- encode 0 (bool True)  == "true"
///     -- encode 0 (bool False) == "false"
@external(javascript, "../json.ffi.mjs", "_Json_wrap")
pub fn bool(value: Bool) -> Value

// NULLS

/// Create a JSON `null` value.
///
///     import Json.Encode exposing (encode, null)
///
///     -- encode 0 null == "null"
@external(javascript, "../json.ffi.mjs", "_Json_encodeNull")
pub fn null() -> Value

// ARRAYS

/// Turn a `List` into a JSON array.
///
///     import Json.Encode as Encode exposing (bool, encode, int, list, string)
///
///     -- encode 0 (list int [1,3,4])       == "[1,3,4]"
///     -- encode 0 (list bool [True,False]) == "[true,false]"
///     -- encode 0 (list string ["a","b"])  == """["a","b"]"""
pub fn list(func: fn(a) -> Value, entries: List(a)) -> Value {
  list.fold(entries, empty_array(), fn(acc, entry) {
    add_entry(func(entry), acc)
  })
  |> wrap()
}

/// Turn an `Array` into a JSON array.
pub fn array(func: fn(a) -> Value, entries: Array(a)) -> Value {
  array.foldl(entries, empty_array(), fn(acc, entry) {
    add_entry(func(entry), acc)
  })
  |> wrap()
}

/// Turn a `Set` into a JSON array.
pub fn set(func: fn(a) -> Value, entries: Set(a)) -> Value {
  set.fold(entries, empty_array(), fn(acc, entry) {
    add_entry(func(entry), acc)
  })
  |> wrap()
}

// OBJECTS

/// Create a JSON object.
///
///     import Json.Encode as Encode
///
///     tom : Encode.Value
///     tom =
///         Encode.object
///             [ ( "name", Encode.string "Tom" )
///             , ( "age", Encode.int 42 )
///             ]
///
///     -- Encode.encode 0 tom == """{"name":"Tom","age":42}"""
pub fn object(pairs: List(#(String, Value))) -> Value {
  list.fold(pairs, empty_object(), fn(acc, pair) {
    let #(k, v) = pair
    add_field(k, v, acc)
  })
  |> wrap()
}

/// Turn a `Dict` into a JSON object.
///
///     import Dict exposing (Dict)
///     import Json.Encode as Encode
///
///     people : Dict String Int
///     people =
///         Dict.fromList [ ( "Tom", 42 ), ( "Sue", 38 ) ]
///
///     -- Encode.encode 0 (Encode.dict identity Encode.int people)
///     --   == """{"Tom":42,"Sue":38}"""
pub fn dict(
  to_key: fn(k) -> String,
  to_value: fn(v) -> Value,
  dictionary: Dict(k, v),
) -> Value {
  dict.fold(dictionary, empty_object(), fn(acc, key, value) {
    add_field(to_key(key), to_value(value), acc)
  })
  |> wrap()
}

// INTERNAL HELPERS

@external(javascript, "../json.ffi.mjs", "_Json_wrap")
fn wrap(value: a) -> Value

@external(javascript, "../json.ffi.mjs", "_Json_emptyArray")
fn empty_array() -> a

@external(javascript, "../json.ffi.mjs", "_Json_emptyObject")
fn empty_object() -> a

@external(javascript, "../json.ffi.mjs", "_Json_addEntry")
fn add_entry(value: Value, array: a) -> a

@external(javascript, "../json.ffi.mjs", "_Json_addField")
fn add_field(key: String, value: Value, object: a) -> a
