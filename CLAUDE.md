# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is `elm` - a Gleam package that ports all `elm/*` packages to Gleam. It's designed to help migrate existing Elm applications to Gleam by providing familiar APIs. The Elm parts have been translated to Gleam while the JavaScript FFI code has been adapted to work with Gleam's JavaScript target.

## Development Commands

### Build
```bash
gleam build
```

### Run tests
```bash
gleam test
```

### Development server
After building, serve the repo root with a static file server to test the HTML examples.

## Architecture

### Core Structure
- `dev/` - Example apps demonstrating usage and used for testing
- `src/elm/` - All ported Elm modules organized by package. The original Elm file is right next to each Gleam file. For example, `array.gleam` and `Array.elm`.
- `test/` - Test files using gleeunit

### Key Modules
- `elm/browser` - Browser programs (sandbox, element, document, application)
- `elm/debugger` - Debugger versions of browser programs  
- `elm/platform` - Core platform primitives, effect managers, and ports
- `elm/html` - HTML generation and attributes/events
- `elm/json` - JSON encoding/decoding
- `elm/time` - Time-based subscriptions
- `elm/task` - Task effect manager
- `elm/virtual_dom` - Virtual DOM implementation

### FFI Integration
Each module has a corresponding `.ffi.mjs` file containing JavaScript implementations. These files:
- Are originally copies of the original Elm kernel modules, which are located next to each `.ffi.mjs` file. For example, `basics.ffi.mjs` and `Basics.js`.
- Adapt the JavaScript to work with Gleam's data structures
- Are automatically copied to the build directory

### Effect Managers
The platform uses effect managers for side effects.
```gleam
effect_managers: [
  task.effect_manager(),
  time.effect_manager(),
  platform.outgoing_port_to_effect_manager(my_port),
]
```

### Ports
Ports work differently than in Elm:
- Define with `platform.outgoing_port()` or `platform.incoming_port()`
- Call with `platform.call_outgoing_port()` or `platform.subscribe_incoming_port()`
- Register effect managers when initializing the app

## Usage Patterns

### Basic Browser Program
```gleam
import elm/browser
import elm/debugger

pub fn main(args) {
  debugger.element(
    init: init,
    view: view,
    update: update,
    flags_decoder: decode.succeed(Nil),
    subscriptions: subscriptions,
    effect_managers: [
      // required effect managers
    ],
  )(args)
}
```

### HTML Integration
The built JavaScript is loaded as ES modules. See `dev/browser_element.html` for integration example.

## Target Audience

This package is intended for migrating existing Elm applications to Gleam. For new Gleam projects, consider using [Lustre](https://github.com/lustre-labs/lustre) instead.

## FFI files

- They are originally copy-paste from Elm.
- Modify them as little as possible.
- Add `import` statements at the top, sorted alphabetically. The `import` statements often use `as` to avoid renaming throughout the file. For example, `import { _VirtualDom_diff as __VirtualDom_diff }` so that it works with `__VirtualDom_diff()` usages in the code.
- Add one `export` statement at the bottom, sorted alphabetically.
- Remove the `F2` to `F9` wrappers around functions. For example, change `var f = F2(function(a, b) {})` into `var f = function(a, b) {}`.
- Turn the `A2` to `A9` calls into regular function calls. For example, change `A2(f, a, b)` into `f(a, b)`.
- Turn `_Utils_Tuple0` into `undefined`.
- Turn `_Utils_Tuple2(a, b)` into `[a, b]`.
- If the implementation of a function is for example just `Elm.Kernel.VirtualDom.keyedNode`, make the Gleam function have `@external(javascript, "./virtual_dom.ffi.mjs", "_VirtualDom_keyedNode")` and no function body.
- Always preserve all comments exactly, even if empty. In Gleam, module comments are `////`, documentation comments are `///` and regular comments are `//`. 

## Elm and Gleam differences

- In Elm, `a |> f b` pipes `a` as the _last_ argument: `f b a`. In Gleam, `a |> f(b)` pipes `a` as the _first_ argument: `f(a, b)`. For `map` and `and_then` function definitions, move the last parameter first, so that it fits better with Gleam pipelines.
