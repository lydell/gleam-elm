//// Fast immutable arrays. The elements in an array must have the same type.

import elm/js_array.{type JsArray}
import gleam/float
import gleam/int
import gleam/list
import gleam/result

/// The array in this module is implemented as a tree with a high branching
/// factor (number of elements at each level). In comparison, the `Dict` has
/// a branching factor of 2 (left or right).
///
/// The higher the branching factor, the more elements are stored at each level.
/// This makes writes slower (more to copy per level), but reads faster
/// (fewer traversals). In practice, 32 is a good compromise.
///
/// The branching factor has to be a power of two (8, 16, 32, 64...). This is
/// because we use the index to tell us which path to take when navigating the
/// tree, and we do this by dividing it into several smaller numbers (see
/// `shift_step` documentation). By dividing the index into smaller numbers, we
/// will always get a range which is a power of two (2 bits gives 0-3, 3 gives
/// 0-7, 4 gives 0-15...).
const branch_factor = 32

/// A number is made up of several bits. For bitwise operations in javascript,
/// numbers are treated as 32-bits integers. The number 1 is represented by 31
/// zeros, and a one. The important thing to take from this, is that a 32-bit
/// integer has enough information to represent several smaller numbers.
///
/// For a branching factor of 32, a 32-bit index has enough information to store 6
/// different numbers in the range of 0-31 (5 bits), and one number in the range of
/// 0-3 (2 bits). This means that the tree of an array can have, at most, a depth
/// of 7.
///
/// An index essentially functions as a map. To figure out which branch to take at
/// any given level of the tree, we need to shift (or move) the correct amount of
/// bits so that those bits are at the front. We can then perform a bitwise and to
/// read which of the 32 branches to take.
///
/// The `shift_step` specifies how many bits are required to represent the branching
/// factor.
const shift_step = 5

/// A mask which, when used in a bitwise and, reads the first `shift_step` bits
/// in a number as a number of its own.
const bit_mask = 31

/// Representation of fast immutable arrays. You can create arrays of integers
/// (`Array(Int)`) or strings (`Array(String)`) or any other type of value you can
/// dream up.
pub opaque type Array(a) {
  Array(
    /// The length of the array.
    length: Int,
    /// How many bits to shift the index to get the slot for the first level of the tree.
    start_shift: Int,
    /// The actual tree.
    tree: Tree(a),
    /// The tail of the array. Inserted into tree when number of elements is equal 
    /// to the branching factor. This is an optimization. It makes operations at the 
    /// end (push, pop, read, write) fast.
    tail: JsArray(a),
  )
}

/// Each level in the tree is represented by a `JsArray` of `Node`s.
/// A `Node` can either be a subtree (the next level of the tree) or, if
/// we're at the bottom, a `JsArray` of values (also known as a leaf).
type Node(a) {
  SubTree(Tree(a))
  Leaf(JsArray(a))
}

type Tree(a) =
  JsArray(Node(a))

/// Return an empty array.
///
///     length(empty()) == 0
pub fn empty() -> Array(a) {
  // `start_shift` is only used when there is at least one `Node` in the
  // `tree`. The minimal value is therefore equal to the `shift_step`.
  Array(
    length: 0,
    start_shift: shift_step,
    tree: js_array.empty(),
    tail: js_array.empty(),
  )
}

/// Determine if an array is empty.
///
///     is_empty(empty()) == True
pub fn is_empty(array: Array(a)) -> Bool {
  array.length == 0
}

/// Return the length of an array.
///
///     length(from_list([1,2,3])) == 3
pub fn length(array: Array(a)) -> Int {
  array.length
}

/// Initialize an array. `initialize n f` creates an array of length `n` with
/// the element at index `i` initialized to the result of `(f i)`.
///
///     initialize(4, fn(i) { i })    == from_list([0,1,2,3])
///     initialize(4, fn(n) { n*n }) == from_list([0,1,4,9])
///     initialize(4, fn(_) { 0 })  == from_list([0,0,0,0])
pub fn initialize(len: Int, func: fn(Int) -> a) -> Array(a) {
  case len <= 0 {
    True -> empty()
    False -> {
      let tail_len = len % branch_factor
      let tail = js_array.initialize(tail_len, len - tail_len, func)
      let initial_from_index = len - tail_len - branch_factor
      initialize_help(func, initial_from_index, len, [], tail)
    }
  }
}

fn initialize_help(
  func: fn(Int) -> a,
  from_index: Int,
  len: Int,
  node_list: List(Node(a)),
  tail: JsArray(a),
) -> Array(a) {
  case from_index < 0 {
    True ->
      builder_to_array(
        False,
        Builder(
          tail: tail,
          node_list: node_list,
          node_list_size: len / branch_factor,
        ),
      )
    False -> {
      let leaf = Leaf(js_array.initialize(branch_factor, from_index, func))
      initialize_help(
        func,
        from_index - branch_factor,
        len,
        [leaf, ..node_list],
        tail,
      )
    }
  }
}

/// Creates an array with a given length, filled with a default element.
///
///     repeat(5, 0)     == from_list([0,0,0,0,0])
///     repeat(3, "cat") == from_list(["cat","cat","cat"])
///
/// Notice that `repeat(3, x)` is the same as `initialize(3, fn(_) { x })`.
pub fn repeat(n: Int, element: a) -> Array(a) {
  initialize(n, fn(_) { element })
}

/// Create an array from a `List`.
pub fn from_list(list: List(a)) -> Array(a) {
  case list {
    [] -> empty()
    _ -> from_list_help(list, [], 0)
  }
}

fn from_list_help(
  list: List(a),
  node_list: List(Node(a)),
  node_list_size: Int,
) -> Array(a) {
  let #(js_array, remaining_items) =
    js_array.initialize_from_list(branch_factor, list)

  case js_array.length(js_array) < branch_factor {
    True ->
      builder_to_array(
        True,
        Builder(
          tail: js_array,
          node_list: node_list,
          node_list_size: node_list_size,
        ),
      )
    False ->
      from_list_help(
        remaining_items,
        [Leaf(js_array), ..node_list],
        node_list_size + 1,
      )
  }
}

/// Return `Ok` with the element at the index or `Error(Nil)` if the index is out of
/// range.
///
///     get(from_list([0,1,2]), 0) == Ok(0)
///     get(from_list([0,1,2]), 2) == Ok(2)
///     get(from_list([0,1,2]), 5) == Error(Nil)
///     get(from_list([0,1,2]), -1) == Error(Nil)
pub fn get(array: Array(a), index: Int) -> Result(a, Nil) {
  case index < 0 || index >= array.length {
    True -> Error(Nil)
    False ->
      case index >= tail_index(array.length) {
        True ->
          Ok(js_array.unsafe_get(int.bitwise_and(bit_mask, index), array.tail))
        False -> Ok(get_help(array.start_shift, index, array.tree))
      }
  }
}

fn get_help(shift: Int, index: Int, tree: Tree(a)) -> a {
  let pos = int.bitwise_and(bit_mask, int.bitwise_shift_right(index, shift))
  case js_array.unsafe_get(pos, tree) {
    SubTree(sub_tree) -> get_help(shift - shift_step, index, sub_tree)
    Leaf(values) ->
      js_array.unsafe_get(int.bitwise_and(bit_mask, index), values)
  }
}

/// Given an array length, return the index of the first element in the tail.
/// Commonly used to check if a given index references something in the tail.
fn tail_index(len: Int) -> Int {
  len
  |> int.bitwise_shift_right(5)
  |> int.bitwise_shift_left(5)
}

/// Set the element at a particular index. Returns an updated array.
/// If the index is out of range, the array is unaltered.
///
///     set(from_list([1,2,3]), 1, 7) == from_list([1,7,3])
pub fn set(array: Array(a), index: Int, value: a) -> Array(a) {
  case index < 0 || index >= array.length {
    True -> array
    False ->
      case index >= tail_index(array.length) {
        True ->
          Array(
            ..array,
            tail: js_array.unsafe_set(
              int.bitwise_and(bit_mask, index),
              value,
              array.tail,
            ),
          )
        False ->
          Array(
            ..array,
            tree: set_help(array.start_shift, index, value, array.tree),
          )
      }
  }
}

fn set_help(shift: Int, index: Int, value: a, tree: Tree(a)) -> Tree(a) {
  let pos = int.bitwise_and(bit_mask, int.bitwise_shift_right(index, shift))
  case js_array.unsafe_get(pos, tree) {
    SubTree(sub_tree) -> {
      let new_sub = set_help(shift - shift_step, index, value, sub_tree)
      js_array.unsafe_set(pos, SubTree(new_sub), tree)
    }
    Leaf(values) -> {
      let new_leaf =
        js_array.unsafe_set(int.bitwise_and(bit_mask, index), value, values)
      js_array.unsafe_set(pos, Leaf(new_leaf), tree)
    }
  }
}

/// Push an element onto the end of an array.
///
///     push(from_list([1,2]), 3) == from_list([1,2,3])
pub fn push(array: Array(a), element: a) -> Array(a) {
  unsafe_replace_tail(js_array.push(element, array.tail), array)
}

/// Replaces the tail of an array. If the length of the tail equals the
/// `branch_factor`, it is inserted into the tree, and the tail cleared.
///
/// WARNING: For performance reasons, this function does not check if the new tail
/// has a length equal to or beneath the `branch_factor`. Make sure this is the case
/// before using this function.
fn unsafe_replace_tail(new_tail: JsArray(a), array: Array(a)) -> Array(a) {
  let original_tail_len = js_array.length(array.tail)
  let new_tail_len = js_array.length(new_tail)
  let new_array_len = array.length + new_tail_len - original_tail_len

  case new_tail_len == branch_factor {
    False ->
      Array(
        length: new_array_len,
        start_shift: array.start_shift,
        tree: array.tree,
        tail: new_tail,
      )
    True -> {
      let overflow =
        int.bitwise_shift_right(new_array_len, shift_step)
        > int.bitwise_shift_left(1, array.start_shift)

      case overflow {
        True -> {
          let new_shift = array.start_shift + shift_step
          let new_tree =
            js_array.singleton(SubTree(array.tree))
            |> insert_tail_in_tree(new_shift, array.length, new_tail)
          Array(
            length: new_array_len,
            start_shift: new_shift,
            tree: new_tree,
            tail: js_array.empty(),
          )
        }
        False ->
          Array(
            length: new_array_len,
            start_shift: array.start_shift,
            tree: insert_tail_in_tree(
              array.tree,
              array.start_shift,
              array.length,
              new_tail,
            ),
            tail: js_array.empty(),
          )
      }
    }
  }
}

fn insert_tail_in_tree(
  tree: Tree(a),
  shift: Int,
  index: Int,
  tail: JsArray(a),
) -> Tree(a) {
  let pos = int.bitwise_and(bit_mask, int.bitwise_shift_right(index, shift))

  case pos >= js_array.length(tree) {
    True ->
      case shift == 5 {
        True -> js_array.push(Leaf(tail), tree)
        False -> {
          let new_sub =
            js_array.empty()
            |> insert_tail_in_tree(shift - shift_step, index, tail)
            |> SubTree
          js_array.push(new_sub, tree)
        }
      }
    False -> {
      let value = js_array.unsafe_get(pos, tree)
      case value {
        SubTree(sub_tree) -> {
          let new_sub =
            sub_tree
            |> insert_tail_in_tree(shift - shift_step, index, tail)
            |> SubTree
          js_array.unsafe_set(pos, new_sub, tree)
        }
        Leaf(_) -> {
          let new_sub =
            js_array.singleton(value)
            |> insert_tail_in_tree(shift - shift_step, index, tail)
            |> SubTree
          js_array.unsafe_set(pos, new_sub, tree)
        }
      }
    }
  }
}

/// Create a list of elements from an array.
///
///     to_list(from_list([3,5,8])) == [3,5,8]
pub fn to_list(array: Array(a)) -> List(a) {
  foldr(array, [], fn(x, acc) { [x, ..acc] })
}

/// Create an indexed list from an array. Each element of the array will be
/// paired with its index.
///
///     to_indexed_list(from_list(["cat","dog"])) == [(0,"cat"), (1,"dog")]
pub fn to_indexed_list(array: Array(a)) -> List(#(Int, a)) {
  let helper = fn(entry, acc) {
    let #(index, list) = acc
    #(index - 1, [#(index, entry), ..list])
  }
  let #(_, result) = foldr(array, #(array.length - 1, []), helper)
  result
}

/// Reduce an array from the right. Read `foldr` as fold from the right.
///
///     foldr(repeat(3, 5), 0, int.add) == 15
pub fn foldr(array: Array(a), initial: b, func: fn(a, b) -> b) -> b {
  js_array.foldr(
    fn(node, acc) { foldr_helper(func, node, acc) },
    js_array.foldr(func, initial, array.tail),
    array.tree,
  )
}

fn foldr_helper(func: fn(a, b) -> b, node: Node(a), acc: b) -> b {
  case node {
    SubTree(sub_tree) ->
      js_array.foldr(
        fn(node, acc) { foldr_helper(func, node, acc) },
        acc,
        sub_tree,
      )
    Leaf(values) -> js_array.foldr(func, acc, values)
  }
}

/// Reduce an array from the left. Read `foldl` as fold from the left.
///
///     foldl(from_list([1,2,3]), [], fn(x, acc) { [x, ..acc] }) == [3,2,1]
pub fn foldl(array: Array(a), initial: b, func: fn(a, b) -> b) -> b {
  js_array.foldl(
    func,
    js_array.foldl(
      fn(node, acc) { foldl_helper(func, node, acc) },
      initial,
      array.tree,
    ),
    array.tail,
  )
}

fn foldl_helper(func: fn(a, b) -> b, node: Node(a), acc: b) -> b {
  case node {
    SubTree(sub_tree) ->
      js_array.foldl(
        fn(node, acc) { foldl_helper(func, node, acc) },
        acc,
        sub_tree,
      )
    Leaf(values) -> js_array.foldl(func, acc, values)
  }
}

/// Keep elements that pass the test.
///
///     filter(from_list([1,2,3,4,5,6]), fn(x) { x % 2 == 0 }) == from_list([2,4,6])
pub fn filter(array: Array(a), predicate: fn(a) -> Bool) -> Array(a) {
  from_list(
    foldr(array, [], fn(x, xs) {
      case predicate(x) {
        True -> [x, ..xs]
        False -> xs
      }
    }),
  )
}

/// Apply a function on every element in an array.
///
///     map(from_list([1,4,9]), float.square_root) == from_list([1.0,2.0,3.0])
pub fn map(array: Array(a), func: fn(a) -> b) -> Array(b) {
  Array(
    length: array.length,
    start_shift: array.start_shift,
    tree: js_array.map(map_helper(func, _), array.tree),
    tail: js_array.map(func, array.tail),
  )
}

fn map_helper(func: fn(a) -> b, node: Node(a)) -> Node(b) {
  case node {
    SubTree(sub_tree) -> SubTree(js_array.map(map_helper(func, _), sub_tree))
    Leaf(values) -> Leaf(js_array.map(func, values))
  }
}

/// Apply a function on every element with its index as first argument.
///
///     indexed_map(from_list([5,5,5]), int.multiply) == from_list([0,5,10])
pub fn indexed_map(array: Array(a), func: fn(Int, a) -> b) -> Array(b) {
  let helper = fn(node, builder) {
    case node {
      SubTree(sub_tree) -> js_array.foldl(helper, builder, sub_tree)
      Leaf(leaf) -> {
        let offset = builder.node_list_size * branch_factor
        let mapped_leaf = Leaf(js_array.indexed_map(func, offset, leaf))
        Builder(
          tail: builder.tail,
          node_list: [mapped_leaf, ..builder.node_list],
          node_list_size: builder.node_list_size + 1,
        )
      }
    }
  }

  let initial_builder =
    Builder(
      tail: js_array.indexed_map(func, tail_index(array.length), array.tail),
      node_list: [],
      node_list_size: 0,
    )

  builder_to_array(True, js_array.foldl(helper, initial_builder, array.tree))
}

/// Append two arrays to a new one.
///
///     append(repeat(2, 42), repeat(3, 81)) == from_list([42,42,81,81,81])
pub fn append(a: Array(a), b: Array(a)) -> Array(a) {
  // The magic number 4 has been found with benchmarks
  case b.length <= branch_factor * 4 {
    True -> {
      let fold_helper = fn(node, array) {
        case node {
          SubTree(tree) -> js_array.foldl(fold_helper, array, tree)
          Leaf(leaf) -> append_help_tree(leaf, array)
        }
      }
      js_array.foldl(fold_helper, a, b.tree)
      |> append_help_tree(b.tail)
    }
    False -> {
      let fold_helper = fn(node, builder) {
        case node {
          SubTree(tree) -> js_array.foldl(fold_helper, builder, tree)
          Leaf(leaf) -> append_help_builder(leaf, builder)
        }
      }
      js_array.foldl(fold_helper, builder_from_array(a), b.tree)
      |> append_help_builder(b.tail)
      |> builder_to_array(True)
    }
  }
}

fn append_help_tree(to_append: JsArray(a), array: Array(a)) -> Array(a) {
  let appended = js_array.append_n(branch_factor, array.tail, to_append)
  let items_to_append = js_array.length(to_append)
  let not_appended =
    branch_factor - js_array.length(array.tail) - items_to_append
  let new_array = unsafe_replace_tail(appended, array)

  case not_appended < 0 {
    True -> {
      let next_tail = js_array.slice(not_appended, items_to_append, to_append)
      unsafe_replace_tail(next_tail, new_array)
    }
    False -> new_array
  }
}

fn append_help_builder(tail: JsArray(a), builder: Builder(a)) -> Builder(a) {
  let appended = js_array.append_n(branch_factor, builder.tail, tail)
  let tail_len = js_array.length(tail)
  let not_appended = branch_factor - js_array.length(builder.tail) - tail_len

  case not_appended < 0 {
    True ->
      Builder(
        tail: js_array.slice(not_appended, tail_len, tail),
        node_list: [Leaf(appended), ..builder.node_list],
        node_list_size: builder.node_list_size + 1,
      )
    False ->
      case not_appended == 0 {
        True ->
          Builder(
            tail: js_array.empty(),
            node_list: [Leaf(appended), ..builder.node_list],
            node_list_size: builder.node_list_size + 1,
          )
        False ->
          Builder(
            tail: appended,
            node_list: builder.node_list,
            node_list_size: builder.node_list_size,
          )
      }
  }
}

/// Get a sub-section of an array: `slice(array, start, end)`. The `start` is a
/// zero-based index where we will start our slice. The `end` is a zero-based index
/// that indicates the end of the slice. The slice extracts up to but not including
/// `end`.
///
///     slice(from_list([0,1,2,3,4]), 0, 3) == from_list([0,1,2])
///     slice(from_list([0,1,2,3,4]), 1, 4) == from_list([1,2,3])
///
/// Both the `start` and `end` indexes can be negative, indicating an offset from
/// the end of the array.
///
///     slice(from_list([0,1,2,3,4]), 1, -1) == from_list([1,2,3])
///     slice(from_list([0,1,2,3,4]), -2, 5) == from_list([3,4])
///
/// This makes it pretty easy to `pop` the last element off of an array:
/// `slice(array, 0, -1)`
pub fn slice(array: Array(a), from: Int, to: Int) -> Array(a) {
  let correct_from = translate_index(from, array)
  let correct_to = translate_index(to, array)

  case correct_from > correct_to {
    True -> empty()
    False ->
      array
      |> slice_right(correct_to)
      |> slice_left(correct_from)
  }
}

/// Given a relative array index, convert it into an absolute one.
///
///     translate_index(-1, some_array) == some_array.length - 1
///     translate_index(-10, some_array) == some_array.length - 10
///     translate_index(5, some_array) == 5
fn translate_index(index: Int, array: Array(a)) -> Int {
  let pos_index = case index < 0 {
    True -> array.length + index
    False -> index
  }

  case pos_index < 0 {
    True -> 0
    False ->
      case pos_index > array.length {
        True -> array.length
        False -> pos_index
      }
  }
}

/// This function slices the tree from the right.
///
/// First, two things are tested:
/// 1. If the array does not need slicing, return the original array.
/// 2. If the array can be sliced by only slicing the tail, slice the tail.
///
/// Otherwise, we do the following:
/// 1. Find the new tail in the tree, promote it to the root tail position and
/// slice it.
/// 2. Slice every sub tree.
/// 3. Promote subTrees until the tree has the correct height.
fn slice_right(array: Array(a), end: Int) -> Array(a) {
  case end == array.length {
    True -> array
    False ->
      case end >= tail_index(array.length) {
        True ->
          Array(
            length: end,
            start_shift: array.start_shift,
            tree: array.tree,
            tail: js_array.slice(0, int.bitwise_and(bit_mask, end), array.tail),
          )
        False -> {
          let end_idx = tail_index(end)
          let depth =
            int.max(1, end_idx - 1)
            |> int.to_float
            |> float.logarithm(int.to_float(branch_factor))
            |> result.unwrap(0.0)
            |> float.floor
            |> float.round

          let new_shift = int.max(5, float.round(depth) * shift_step)

          Array(
            length: end,
            start_shift: new_shift,
            tree: array.tree
              |> slice_tree(array.start_shift, end_idx)
              |> hoist_tree(array.start_shift, new_shift),
            tail: fetch_new_tail(array.start_shift, end, end_idx, array.tree),
          )
        }
      }
  }
}

/// Slice and return the `Leaf` node after what is to be the last node
/// in the sliced tree.
fn fetch_new_tail(
  shift: Int,
  end: Int,
  tree_end: Int,
  tree: Tree(a),
) -> JsArray(a) {
  let pos = int.bitwise_and(bit_mask, int.bitwise_shift_right(tree_end, shift))

  case js_array.unsafe_get(pos, tree) {
    SubTree(sub) -> fetch_new_tail(shift - shift_step, end, tree_end, sub)
    Leaf(values) -> js_array.slice(0, int.bitwise_and(bit_mask, end), values)
  }
}

/// Shorten the root `Node` of the tree so it is long enough to contain
/// the `Node` indicated by `end_idx`. Then recursively perform the same operation
/// to the last node of each `SubTree`.
fn slice_tree(tree: Tree(a), shift: Int, end_idx: Int) -> Tree(a) {
  let last_pos =
    int.bitwise_and(bit_mask, int.bitwise_shift_right(end_idx, shift))

  case js_array.unsafe_get(last_pos, tree) {
    SubTree(sub) -> {
      let new_sub = slice_tree(sub, shift - shift_step, end_idx)
      case js_array.length(new_sub) == 0 {
        True ->
          // The sub is empty, slice it away
          js_array.slice(0, last_pos, tree)
        False ->
          tree
          |> js_array.slice(0, last_pos + 1)
          |> js_array.unsafe_set(last_pos, SubTree(new_sub))
      }
    }
    // This is supposed to be the new tail. Fetched by `fetch_new_tail`.
    // Slice up to, but not including, this point.
    Leaf(_) -> js_array.slice(0, last_pos, tree)
  }
}

/// The tree is supposed to be of a certain depth. Since slicing removes
/// elements, it could be that the tree should have a smaller depth
/// than it had originally. This function shortens the height if it is necessary
/// to do so.
fn hoist_tree(tree: Tree(a), old_shift: Int, new_shift: Int) -> Tree(a) {
  case old_shift <= new_shift || js_array.length(tree) == 0 {
    True -> tree
    False ->
      case js_array.unsafe_get(0, tree) {
        SubTree(sub) -> hoist_tree(sub, old_shift - shift_step, new_shift)
        Leaf(_) -> tree
      }
  }
}

/// This function slices the tree from the left. Such an operation will change
/// the index of every element after the slice. Which means that we will have to
/// rebuild the array.
///
/// First, two things are tested:
/// 1. If the array does not need slicing, return the original array.
/// 2. If the slice removes every element but those in the tail, slice the tail and
/// set the tree to the empty array.
///
/// Otherwise, we do the following:
/// 1. Add every leaf node in the tree to a list.
/// 2. Drop the nodes which are supposed to be sliced away.
/// 3. Slice the head node of the list, which represents the start of the new array.
/// 4. Create a builder with the tail set as the node from the previous step.
/// 5. Append the remaining nodes into this builder, and create the array.
fn slice_left(array: Array(a), from: Int) -> Array(a) {
  case from == 0 {
    True -> array
    False ->
      case from >= tail_index(array.length) {
        True ->
          Array(
            length: array.length - from,
            start_shift: shift_step,
            tree: js_array.empty(),
            tail: js_array.slice(
              from - tail_index(array.length),
              js_array.length(array.tail),
              array.tail,
            ),
          )
        False -> {
          let helper = fn(node, acc) {
            case node {
              SubTree(sub_tree) -> js_array.foldr(helper, acc, sub_tree)
              Leaf(leaf) -> [leaf, ..acc]
            }
          }

          let leaf_nodes = js_array.foldr(helper, [array.tail], array.tree)
          let skip_nodes = from / branch_factor
          let nodes_to_insert = list.drop(leaf_nodes, skip_nodes)

          case nodes_to_insert {
            [] -> empty()
            [head, ..rest] -> {
              let first_slice = from - skip_nodes * branch_factor
              let initial_builder =
                Builder(
                  tail: js_array.slice(first_slice, js_array.length(head), head),
                  node_list: [],
                  node_list_size: 0,
                )
              list.fold(rest, initial_builder, append_help_builder)
              |> builder_to_array(True)
            }
          }
        }
      }
  }
}

/// A builder contains all information necessary to build an array. Adding
/// information to the builder is fast. A builder is therefore a suitable
/// intermediary for constructing arrays.
type Builder(a) {
  Builder(tail: JsArray(a), node_list: List(Node(a)), node_list_size: Int)
}

/// The empty builder.
fn empty_builder() -> Builder(a) {
  Builder(tail: js_array.empty(), node_list: [], node_list_size: 0)
}

/// Converts an array to a builder.
fn builder_from_array(array: Array(a)) -> Builder(a) {
  let helper = fn(node, acc) {
    case node {
      SubTree(sub_tree) -> js_array.foldl(helper, acc, sub_tree)
      Leaf(_) -> [node, ..acc]
    }
  }
  Builder(
    tail: array.tail,
    node_list: js_array.foldl(helper, [], array.tree),
    node_list_size: array.length / branch_factor,
  )
}

/// Construct an array with the information in a given builder.
///
/// Due to the nature of `List` the list of nodes in a builder will often
/// be in reverse order (that is, the first leaf of the array is the last
/// node in the node list). This function therefore allows the caller to
/// specify if the node list should be reversed before building the array.
fn builder_to_array(reverse_node_list: Bool, builder: Builder(a)) -> Array(a) {
  case builder.node_list_size == 0 {
    True ->
      Array(
        length: js_array.length(builder.tail),
        start_shift: shift_step,
        tree: js_array.empty(),
        tail: builder.tail,
      )
    False -> {
      let tree_len = builder.node_list_size * branch_factor
      let depth =
        int.to_float(tree_len - 1)
        |> float.logarithm(int.to_float(branch_factor))
        |> result.unwrap(0.0)
        |> float.floor

      let correct_node_list = case reverse_node_list {
        True -> list.reverse(builder.node_list)
        False -> builder.node_list
      }

      let tree = tree_from_builder(correct_node_list, builder.node_list_size)

      Array(
        length: js_array.length(builder.tail) + tree_len,
        start_shift: int.max(5, float.round(depth) * shift_step),
        tree: tree,
        tail: builder.tail,
      )
    }
  }
}

/// Takes a list of leaves and an `Int` specifying how many leaves there are,
/// and builds a tree structure to be used in an `Array`.
fn tree_from_builder(node_list: List(Node(a)), node_list_size: Int) -> Tree(a) {
  let new_node_size =
    int.to_float(node_list_size) /. int.to_float(branch_factor)
    |> float.ceiling
    |> float.round

  case new_node_size == 1 {
    True -> {
      let #(result, _) = js_array.initialize_from_list(branch_factor, node_list)
      result
    }
    False ->
      tree_from_builder(
        compress_nodes(node_list, []),
        float.round(new_node_size),
      )
  }
}

/// Takes a list of nodes and return a list of `SubTree`s containing those
/// nodes.
fn compress_nodes(nodes: List(Node(a)), acc: List(Node(a))) -> List(Node(a)) {
  let #(node, remaining_nodes) =
    js_array.initialize_from_list(branch_factor, nodes)
  let new_acc = [SubTree(node), ..acc]

  case remaining_nodes {
    [] -> list.reverse(new_acc)
    _ -> compress_nodes(remaining_nodes, new_acc)
  }
}
