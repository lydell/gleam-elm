//// This library provides an immutable version of native javascript arrays.
////
//// NOTE: All manipulations cause a copy of the entire array, this can be slow.
//// For general purpose use, try the `Array` module instead.

/// Representation of a javascript array.
pub type JsArray(a)

/// Return an empty array.
@external(javascript, "./js_array.ffi.mjs", "_JsArray_empty")
pub fn empty() -> JsArray(a)

/// Return an array containing a single value.
@external(javascript, "./js_array.ffi.mjs", "_JsArray_singleton")
pub fn singleton(value: a) -> JsArray(a)

/// Return the length of the array.
@external(javascript, "./js_array.ffi.mjs", "_JsArray_length")
pub fn length(array: JsArray(a)) -> Int

/// Initialize an array. `initialize n offset fn` creates an array of length `n`
/// with the element at index `i` initialized to the result of `(f (i + offset))`.
///
/// The offset parameter is there so one can avoid creating a closure for this use
/// case. This is an optimization that has proved useful in the `Array` module.
///
///     initialize 3 5 identity == [5,6,7]
@external(javascript, "./js_array.ffi.mjs", "_JsArray_initialize")
pub fn initialize(size: Int, offset: Int, func: fn(Int) -> a) -> JsArray(a)

/// Initialize an array from a list. `initialize_from_list n ls` creates an array of,
/// at most, `n` elements from the list. The return value is a tuple containing the
/// created array as well as a list without the first `n` elements.
///
/// This function was created specifically for the `Array` module, which never wants
/// to create `JsArray`s above a certain size. That being said, because every
/// manipulation of `JsArray` results in a copy, users should always try to keep
/// these as small as possible. The `n` parameter should always be set to a
/// reasonably small value.
@external(javascript, "./js_array.ffi.mjs", "_JsArray_initializeFromList")
pub fn initialize_from_list(max: Int, list: List(a)) -> #(JsArray(a), List(a))

/// Returns the element at the given index.
///
/// WARNING: This function does not perform bounds checking.
/// Make sure you know the index is within bounds when using this function.
@external(javascript, "./js_array.ffi.mjs", "_JsArray_unsafeGet")
pub fn unsafe_get(index: Int, array: JsArray(a)) -> a

/// Sets the element at the given index.
///
/// WARNING: This function does not perform bounds checking.
/// Make sure you know the index is within bounds when using this function.
@external(javascript, "./js_array.ffi.mjs", "_JsArray_unsafeSet")
pub fn unsafe_set(index: Int, value: a, array: JsArray(a)) -> JsArray(a)

/// Push an element onto the array.
@external(javascript, "./js_array.ffi.mjs", "_JsArray_push")
pub fn push(value: a, array: JsArray(a)) -> JsArray(a)

/// Reduce the array from the left.
@external(javascript, "./js_array.ffi.mjs", "_JsArray_foldl")
pub fn foldl(func: fn(a, b) -> b, acc: b, array: JsArray(a)) -> b

/// Reduce the array from the right.
@external(javascript, "./js_array.ffi.mjs", "_JsArray_foldr")
pub fn foldr(func: fn(a, b) -> b, acc: b, array: JsArray(a)) -> b

/// Apply a function on every element in an array.
@external(javascript, "./js_array.ffi.mjs", "_JsArray_map")
pub fn map(func: fn(a) -> b, array: JsArray(a)) -> JsArray(b)

/// Apply a function on every element and its index in an array.
/// An offset allows to modify the index passed to the function.
///
///     indexed_map #(,) 5 (repeat 3 3) == Array [(5,3), (6,3), (7,3)]
@external(javascript, "./js_array.ffi.mjs", "_JsArray_indexedMap")
pub fn indexed_map(
  func: fn(Int, a) -> b,
  offset: Int,
  array: JsArray(a),
) -> JsArray(b)

/// Get a sub section of an array: `(slice start end array)`.
/// The `start` is a zero-based index where we will start our slice.
/// The `end` is a zero-based index that indicates the end of the slice.
/// The slice extracts up to, but not including, the `end`.
///
/// Both `start` and `end` can be negative, indicating an offset from the end
/// of the array. Popping the last element of the array is therefore:
/// `slice 0 -1 arr`.
///
/// In the case of an impossible slice, the empty array is returned.
@external(javascript, "./js_array.ffi.mjs", "_JsArray_slice")
pub fn slice(start: Int, end: Int, array: JsArray(a)) -> JsArray(a)

/// Appends `n` elements from array `b` onto array `a`: `(append_n n a b)`.
///
/// The `n` parameter is required by the `Array` module, which never wants to
/// create `JsArray`s above a certain size, even when appending.
@external(javascript, "./js_array.ffi.mjs", "_JsArray_appendN")
pub fn append_n(n: Int, dest: JsArray(a), source: JsArray(a)) -> JsArray(a)
