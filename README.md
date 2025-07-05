# elm_compat

[![Package Version](https://img.shields.io/hexpm/v/elm_compat)](https://hex.pm/packages/elm_compat)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/elm_compat/)

All `elm/*` packages ported to Gleam. `elm/*` packages are implemented partially in Elm, and partially in plain JavaScript. The Elm parts have been translated to Gleam. The JavaScript parts have been copy-pasted as-is and have then been adjusted slightly to work with Gleam.

The idea is that this could help you migrate an existing Elm app to Gleam. If you’re starting from scratch, you might want to check out [Lustre](https://github.com/lustre-labs/lustre) instead.

```sh
gleam add elm_compat@1
```
```gleam
import elm/browser

pub fn main(args) {
  debugger.element(
    init:,
    view:,
    update:,
    flags_decoder:,
    subscriptions:,
    effect_managers: [],
  )(args)
}
```

Further documentation can be found at <https://hexdocs.pm/elm_compat>.

## Development

Build:

```
gleam build
```

Then serve the repo root with a static file server.
