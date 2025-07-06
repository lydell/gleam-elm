//// Turn JSON values into Elm values. Definitely check out this [intro to
//// JSON decoders][guide] to get a feel for how this library works!
////
//// [guide]: https://guide.elm-lang.org/effects/json.html

import elm/array
import elm/json/encode
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option}
import gleam/string

// PRIMITIVES

/// A value that knows how to decode JSON values.
///
/// There is a whole section in `guide.elm-lang.org` about decoders, so [check it
/// out](https://guide.elm-lang.org/interop/json.html) for a more comprehensive
/// introduction!
pub type Decoder(a)

/// Decode a JSON string into an Elm `String`.
///
///     decodeString string "true"              == Err ...
///     decodeString string "42"                == Err ...
///     decodeString string "3.14"              == Err ...
///     decodeString string "\"hello\""         == Ok "hello"
///     decodeString string "{ \"hello\": 42 }" == Err ...
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

// DATA STRUCTURES

/// Decode a nullable JSON value into an Elm value.
///
///     decodeString (nullable int) "13"    == Ok (Some(13))
///     decodeString (nullable int) "42"    == Ok (Some(42))
///     decodeString (nullable int) "null"  == Ok None
///     decodeString (nullable int) "true"  == Err ..
pub fn nullable(decoder: Decoder(a)) -> Decoder(Option(a)) {
  one_of([null(option.None), map(decoder, option.Some)])
}

/// Decode a JSON array into an Elm `List`.
///
///     decodeString (list int) "[1,2,3]" == Ok [1, 2, 3]
///     decodeString (list bool) "[true,false]" == Ok [True, False]
@external(javascript, "../json.ffi.mjs", "_Json_decodeList")
pub fn list(decoder: Decoder(a)) -> Decoder(List(a))

/// Decode a JSON array into an Elm `Array`.
///
///     decodeString (array int) "[1,2,3]" == Ok (Array.fromList [1, 2, 3])
///     decodeString (array bool) "[true,false]" == Ok (Array.fromList [True, False])
@external(javascript, "../json.ffi.mjs", "_Json_decodeArray")
pub fn array(decoder: Decoder(a)) -> Decoder(array.Array(a))

/// Decode a JSON object into an Elm `Dict`.
///
///     decodeString (dict int) "{ \"alice\": 42, \"bob\": 99 }"
///         == Ok (Dict.fromList [#("alice", 42), #("bob", 99)])
///
/// If you need the keys (like `"alice"` and `"bob"`) available in the `Dict`
/// values as well, I recommend using a (private) intermediate data structure like
/// `Info` in this example:
///
///     module User exposing (User, decoder)
///
///     import Dict
///     import Json.Decode exposing (..)
///
///     type alias User =
///         { name : String
///         , height : Float
///         , age : Int
///         }
///
///     decoder : Decoder (Dict.Dict String User)
///     decoder =
///         map (Dict.map infoToUser) (dict infoDecoder)
///
///     type alias Info =
///         { height : Float
///         , age : Int
///         }
///
///     infoDecoder : Decoder Info
///     infoDecoder =
///         map2 Info
///             (field "height" float)
///             (field "age" int)
///
///     infoToUser : String -> Info -> User
///     infoToUser name { height, age } =
///         User name height age
///
/// So now JSON like `{ "alice": { height: 1.6, age: 33 }}` are turned into
/// dictionary values like `Dict.singleton "alice" (User "alice" 1.6 33)` if
/// you need that.
pub fn dict(decoder: Decoder(a)) -> Decoder(Dict(String, a)) {
  map(key_value_pairs(decoder), dict.from_list)
}

/// Decode a JSON object into an Elm `List` of pairs.
///
///     decodeString (keyValuePairs int) "{ \"alice\": 42, \"bob\": 99 }"
///         == Ok [#("alice", 42), #("bob", 99)]
@external(javascript, "../json.ffi.mjs", "_Json_decodeKeyValuePairs")
pub fn key_value_pairs(decoder: Decoder(a)) -> Decoder(List(#(String, a)))

/// Decode a JSON array that has one or more elements. This comes up if you
/// want to enable drag-and-drop of files into your application. You would pair
/// this function with [`elm/file`]() to write a `dropDecoder` like this:
///
///     import File exposing (File)
///     import Json.Decoder as D
///
///     type Msg
///         = GotFiles File (List Files)
///
///     inputDecoder : D.Decoder Msg
///     inputDecoder =
///         D.at ["dataTransfer", "files"] (D.oneOrMore GotFiles File.decoder)
///
/// This captures the fact that you can never drag-and-drop zero files.
pub fn one_or_more(
  to_value: fn(a, List(a)) -> value,
  decoder: Decoder(a),
) -> Decoder(value) {
  list(decoder)
  |> and_then(one_or_more_help(to_value, _))
}

fn one_or_more_help(
  to_value: fn(a, List(a)) -> value,
  xs: List(a),
) -> Decoder(value) {
  case xs {
    [] -> fail("a ARRAY with at least ONE element")
    [y, ..ys] -> succeed(to_value(y, ys))
  }
}

// OBJECT PRIMITIVES

/// Decode a JSON object, requiring a particular field.
///
///     decodeString (field "x" int) "{ \"x\": 3 }" == Ok 3
///     decodeString (field "x" int) "{ \"x\": 3, \"y\": 4 }" == Ok 3
///     decodeString (field "x" int) "{ \"x\": true }" == Err ...
///     decodeString (field "x" int) "{ \"y\": 4 }" == Err ...
///     decodeString (field "name" string) "{ \"name\": \"tom\" }" == Ok "tom"
///
/// The object _can_ have other fields. Lots of them! The only thing this decoder
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
///     field "person" (field "name" string) == at ["person", "name"] string
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

// INCONSISTENT STRUCTURE

/// Helpful for dealing with optional fields. Here are a few slightly different
/// examples:
///
///     json = """{ "name": "tom", "age": 42 }"""
///
///     decodeString (maybe (field "age"    int  )) json == Ok (Some(42))
///     decodeString (maybe (field "name"   int  )) json == Ok None
///     decodeString (maybe (field "height" float)) json == Ok None
///
///     decodeString (field "age"    (maybe int  )) json == Ok (Some(42))
///     decodeString (field "name"   (maybe int  )) json == Ok None
///     decodeString (field "height" (maybe float)) json == Err ...
///
/// Notice the last example! It is saying we _must_ have a field named `height` and
/// the content _may_ be a float. There is no `height` field, so the decoder fails.
///
/// Point is, `maybe` will make exactly what it contains conditional. For optional
/// fields, this means you probably want it _outside_ a use of `field` or `at`.
pub fn maybe(decoder: Decoder(a)) -> Decoder(Option(a)) {
  one_of([map(decoder, option.Some), succeed(option.None)])
}

/// Try a bunch of different decoders. This can be useful if the JSON may come
/// in a couple different formats. For example, say you want to read an array of
/// numbers, but some of them are `null`.
///
///     import String
///
///     badInt : Decoder Int
///     badInt =
///         oneOf [ int, null 0 ]
///
///     -- decodeString (list badInt) "[1,2,null,4]" == Ok [1,2,0,4]
///
/// Why would someone generate JSON like this? Questions like this are not good
/// for your health. The point is that you can use `oneOf` to handle situations
/// like this!
///
/// You could also use `oneOf` to help version your data. Try the latest format,
/// then a few older ones that you still support. You could use `andThen` to be
/// even more particular if you wanted.
@external(javascript, "../json.ffi.mjs", "_Json_oneOf")
pub fn one_of(decoders: List(Decoder(a))) -> Decoder(a)

// MAPPING

/// Transform a decoder. Maybe you just want to know the length of a string:
///
///     import String
///
///     stringLength : Decoder Int
///     stringLength =
///         map String.length string
///
/// It is often helpful to use `map` with `oneOf`, like when defining `nullable`:
///
///     nullable : Decoder a -> Decoder (Maybe a)
///     nullable decoder =
///         oneOf
///             [ null Nothing
///             , map Just decoder
///             ]
@external(javascript, "../json.ffi.mjs", "_Json_map")
pub fn map(decoder: Decoder(a), tagger: fn(a) -> value) -> Decoder(value)

/// Try two decoders and then combine the result. We can use this to decode
/// objects with many fields:
///
///     type alias Point =
///         { x : Float, y : Float }
///
///     point : Decoder Point
///     point =
///         map2 Point
///             (field "x" float)
///             (field "y" float)
///
///     -- decodeString point """{ "x": 3, "y": 4 }""" == Ok { x = 3, y = 4 }
///
/// It tries each individual decoder and puts the result together with the `Point`
/// constructor.
@external(javascript, "../json.ffi.mjs", "_Json_map2")
pub fn map2(
  decoder_a: Decoder(a),
  decoder_b: Decoder(b),
  combiner: fn(a, b) -> value,
) -> Decoder(value)

/// Try three decoders and then combine the result. We can use this to decode
/// objects with many fields:
///
///     type alias Person =
///         { name : String, age : Int, height : Float }
///
///     person : Decoder Person
///     person =
///         map3 Person
///             (at [ "name" ] string)
///             (at [ "info", "age" ] int)
///             (at [ "info", "height" ] float)
///
///     -- json = """{ "name": "tom", "info": { "age": 42, "height": 1.8 } }"""
///     -- decodeString person json == Ok { name = "tom", age = 42, height = 1.8 }
///
/// Like `map2` it tries each decoder in order and then give the results to the
/// `Person` constructor. That can be any function though!
@external(javascript, "../json.ffi.mjs", "_Json_map3")
pub fn map3(
  decoder_a: Decoder(a),
  decoder_b: Decoder(b),
  decoder_c: Decoder(c),
  combiner: fn(a, b, c) -> value,
) -> Decoder(value)

///
@external(javascript, "../json.ffi.mjs", "_Json_map4")
pub fn map4(
  decoder_a: Decoder(a),
  decoder_b: Decoder(b),
  decoder_c: Decoder(c),
  decoder_d: Decoder(d),
  combiner: fn(a, b, c, d) -> value,
) -> Decoder(value)

///
@external(javascript, "../json.ffi.mjs", "_Json_map5")
pub fn map5(
  decoder_a: Decoder(a),
  decoder_b: Decoder(b),
  decoder_c: Decoder(c),
  decoder_d: Decoder(d),
  decoder_e: Decoder(e),
  combiner: fn(a, b, c, d, e) -> value,
) -> Decoder(value)

///
@external(javascript, "../json.ffi.mjs", "_Json_map6")
pub fn map6(
  decoder_a: Decoder(a),
  decoder_b: Decoder(b),
  decoder_c: Decoder(c),
  decoder_d: Decoder(d),
  decoder_e: Decoder(e),
  decoder_f: Decoder(f),
  combiner: fn(a, b, c, d, e, f) -> value,
) -> Decoder(value)

///
@external(javascript, "../json.ffi.mjs", "_Json_map7")
pub fn map7(
  decoder_a: Decoder(a),
  decoder_b: Decoder(b),
  decoder_c: Decoder(c),
  decoder_d: Decoder(d),
  decoder_e: Decoder(e),
  decoder_f: Decoder(f),
  decoder_g: Decoder(g),
  combiner: fn(a, b, c, d, e, f, g) -> value,
) -> Decoder(value)

///
@external(javascript, "../json.ffi.mjs", "_Json_map8")
pub fn map8(
  decoder_a: Decoder(a),
  decoder_b: Decoder(b),
  decoder_c: Decoder(c),
  decoder_d: Decoder(d),
  decoder_e: Decoder(e),
  decoder_f: Decoder(f),
  decoder_g: Decoder(g),
  decoder_h: Decoder(h),
  combiner: fn(a, b, c, d, e, f, g, h) -> value,
) -> Decoder(value)

// RUN DECODERS

/// Parse the given string into a JSON value and then run the `Decoder` on it.
/// This will fail if the string is not well-formed JSON or if the `Decoder`
/// fails for some reason.
///
///     decodeString int "4"     == Ok 4
///     decodeString int "1 + 2" == Err ...
@external(javascript, "../json.ffi.mjs", "_Json_runOnString")
pub fn decode_string(
  decoder: Decoder(a),
  json_string: String,
) -> Result(a, Error)

/// Run a `Decoder` on some JSON `Value`. You can send these JSON values
/// through ports, so that is probably the main time you would use this function.
@external(javascript, "../json.ffi.mjs", "_Json_run")
pub fn decode_value(decoder: Decoder(a), value: Value) -> Result(a, Error)

/// Represents a JavaScript value.
pub type Value =
  encode.Value

/// A structured error describing exactly how the decoder failed. You can use
/// this to create more elaborate visualizations of a decoder problem. For example,
/// you could show the entire JSON object and show the part causing the failure in
/// red.
pub type Error {
  Field(String, Error)
  Index(Int, Error)
  OneOf(List(Error))
  Failure(String, Value)
}

/// Convert a decoding error into a `String` that is nice for debugging.
///
/// It produces multiple lines of output, so you may want to peek at it with
/// something like this:
///
///     import Html
///     import Json.Decode as Decode
///
///     errorToHtml : Decode.Error -> Html.Html msg
///     errorToHtml error =
///         Html.pre [] [ Html.text (Decode.errorToString error) ]
///
/// **Note:** It would be cool to do nicer coloring and fancier HTML, but I wanted
/// to avoid having an `elm/html` dependency for now. It is totally possible to
/// crawl the `Error` structure and create this separately though!
pub fn error_to_string(error: Error) -> String {
  error_to_string_help(error, [])
}

fn error_to_string_help(error: Error, context: List(String)) -> String {
  case error {
    Field(f, err) -> {
      let field_name = case is_simple(f) {
        True -> "." <> f
        False -> "['" <> f <> "']"
      }
      error_to_string_help(err, [field_name, ..context])
    }
    Index(i, err) -> {
      let index_name = "[" <> string.inspect(i) <> "]"
      error_to_string_help(err, [index_name, ..context])
    }
    OneOf(errors) ->
      case errors {
        [] ->
          "Ran into a Json.Decode.oneOf with no possibilities"
          <> case context {
            [] -> "!"
            _ -> " at json" <> string.join(list.reverse(context), "")
          }
        [err] -> error_to_string_help(err, context)
        _ -> {
          let starter = case context {
            [] -> "Json.Decode.oneOf"
            _ ->
              "The Json.Decode.oneOf at json"
              <> string.join(list.reverse(context), "")
          }
          let introduction =
            starter
            <> " failed in the following "
            <> string.inspect(list.length(errors))
            <> " ways:"
          string.join(
            [introduction, ..list.index_map(errors, error_one_of)],
            "\n\n",
          )
        }
      }
    Failure(msg, json) -> {
      let introduction = case context {
        [] -> "Problem with the given value:\n\n"
        _ ->
          "Problem with the value at json"
          <> string.join(list.reverse(context), "")
          <> ":\n\n    "
      }
      introduction <> indent(encode.encode(json, 4)) <> "\n\n" <> msg
    }
  }
}

fn error_one_of(error: Error, i: Int) -> String {
  "\n\n(" <> string.inspect(i + 1) <> ") " <> indent(error_to_string(error))
}

fn indent(str: String) -> String {
  string.join(string.split(str, "\n"), "\n    ")
}

/// The Elm implementation is: `Char.isAlpha char && String.all Char.isAlphaNum rest`.
/// In Gleam, we do that with a regex, to avoid depending on `Char`.
@external(javascript, "../json.ffi.mjs", "_Json_isSimpleFieldName")
fn is_simple(name: String) -> Bool

// FANCY DECODING

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

/// Create decoders that depend on previous results. If you are creating
/// versioned data, you might do something like this:
///
///     info : Decoder Info
///     info =
///         field "version" int
///             |> andThen infoHelp
///
///     infoHelp : Int -> Decoder Info
///     infoHelp version =
///         case version of
///             4 ->
///                 infoDecoder4
///
///             3 ->
///                 infoDecoder3
///
///             _ ->
///                 fail <|
///                     "Trying to decode info, but version "
///                         ++ toString version
///                         ++ " is not supported."
///
///     -- infoDecoder4 : Decoder Info
///     -- infoDecoder3 : Decoder Info
@external(javascript, "../json.ffi.mjs", "_Json_andThen")
pub fn and_then(decoder: Decoder(a), f: fn(a) -> Decoder(b)) -> Decoder(b)

/// Sometimes you have JSON with recursive structure, like nested comments.
/// You can use `lazy` to make sure your decoder unrolls lazily.
///
///     type alias Comment =
///         { message : String
///         , responses : Responses
///         }
///
///     type Responses
///         = Responses (List Comment)
///
///     comment : Decoder Comment
///     comment =
///         map2 Comment
///             (field "message" string)
///             (field "responses" (map Responses (list (lazy (\_ -> comment)))))
///
/// If we had said `list comment` instead, we would start expanding the value
/// infinitely. What is a `comment`? It is a decoder for objects where the
/// `responses` field contains comments. What is a `comment` though? Etc.
///
/// By using `list (lazy (\_ -> comment))` we make sure the decoder only expands
/// to be as deep as the JSON we are given. You can read more about recursive data
/// structures [here].
///
/// [here]: https://github.com/elm/compiler/blob/master/hints/recursive-alias.md
pub fn lazy(thunk: fn() -> Decoder(a)) -> Decoder(a) {
  and_then(succeed(Nil), fn(_) { thunk() })
}

/// Do not do anything with a JSON value, just bring it into Elm as a `Value`.
/// This can be useful if you have particularly complex data that you would like to
/// deal with later. Or if you are going to send it out a port and do not care
/// about its structure.
@external(javascript, "../json.ffi.mjs", "_Json_decodeValue")
pub fn value() -> Decoder(Value)

/// Decode a `null` value into some Elm value.
///
///     decodeString (null False) "null" == Ok False
///     decodeString (null 42) "null"    == Ok 42
///     decodeString (null 42) "42"      == Err ..
///     decodeString (null 42) "false"   == Err ..
///
/// So if you ever see a `null`, this will return whatever value you specified.
@external(javascript, "../json.ffi.mjs", "_Json_decodeNull")
pub fn null(value: a) -> Decoder(a)
