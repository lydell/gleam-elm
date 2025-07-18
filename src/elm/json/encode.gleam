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
///     let compact = encode.encode(tom, 0)
///     // {"name":"Tom","age":42}
///
///     let readable = encode.encode(tom, 4)
///     // {
///     //     "name": "Tom",
///     //     "age": 42
///     // }
@external(javascript, "../json.ffi.mjs", "_Json_encode")
pub fn encode(value: Value, indent: Int) -> String

// PRIMITIVES

/// Turn a `String` into a JSON string.
///
///     import elm/json/encode
///
///     // encode.encode(encode.string(""), 0)      == "\"\""
///     // encode.encode(encode.string("abc"), 0)   == "\"abc\""
///     // encode.encode(encode.string("hello"), 0) == "\"hello\""
@external(javascript, "../json.ffi.mjs", "_Json_wrap")
pub fn string(value: String) -> Value

/// Turn an `Int` into a JSON number.
///
///     import elm/json/encode
///
///     // encode.encode(encode.int(42), 0) == "42"
///     // encode.encode(encode.int(-7), 0) == "-7"
///     // encode.encode(encode.int(0), 0)  == "0"
@external(javascript, "../json.ffi.mjs", "_Json_wrap")
pub fn int(value: Int) -> Value

/// Turn a `Float` into a JSON number.
///
///     import elm/json/encode
///
///     // encode.encode(encode.float(3.14), 0)     == "3.14"
///     // encode.encode(encode.float(1.618), 0)    == "1.618"
///     // encode.encode(encode.float(-42.0), 0)      == "-42"
///     // encode.encode(encode.float(nanf()), 0)      == "null"
///     // encode.encode(encode.float(infinityf()), 0) == "null"
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
///     import elm/json/encode
///
///     // encode.encode(encode.bool(True), 0)  == "true"
///     // encode.encode(encode.bool(False), 0) == "false"
@external(javascript, "../json.ffi.mjs", "_Json_wrap")
pub fn bool(value: Bool) -> Value

// NULLS

/// Create a JSON `null` value.
///
///     import elm/json/encode
///
///     // encode.encode(encode.null(), 0) == "null"
@external(javascript, "../json.ffi.mjs", "_Json_encodeNull")
pub fn null() -> Value

// ARRAYS

/// Turn a `List` into a JSON array.
///
///     import elm/json/encode
///
///     // encode.encode(encode.list(encode.int, [1,3,4]), 0)       == "[1,3,4]"
///     // encode.encode(encode.list(encode.bool, [True,False]), 0) == "[true,false]"
///     // encode.encode(encode.list(encode.string, ["a","b"]), 0)  == """["a","b"]"""
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
///     import gleam/dict
///     import elm/json/encode
///
///     let people: dict.Dict(String, Int) = 
///       dict.from_list([("Tom", 42), ("Sue", 38)])
///
///     // encode.encode(encode.dict(fn(x) { x }, encode.int, people), 0)
///     //   == """{"Tom":42,"Sue":38}"""
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
