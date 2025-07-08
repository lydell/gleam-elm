# Gleam Elm

<!--
[![Package Version](https://img.shields.io/hexpm/v/elm)](https://hex.pm/packages/elm)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/elm/)
-->

[Elm](https://elm-lang.org/) ported to [Gleam](https://gleam.run/). Specifically, all `elm/*` packages ported to Gleam. `elm/*` packages are implemented partially in Elm, and partially in plain JavaScript. The Elm parts have been translated to Gleam. The JavaScript parts have been copy-pasted as-is and have then been adjusted slightly to work with Gleam.

The idea is that this could help you migrate an existing Elm app to Gleam. If you’re starting from scratch, you might want to check out [Lustre](https://github.com/lustre-labs/lustre) instead.

Gleam and Elm are very similar languages. With this package, a migration basically becomes a job of translating syntax, with everything else working the same.

Perhaps [elm-syntax-to-gleam](https://github.com/lue-bird/elm-syntax-to-gleam) can be used to do the syntax translation.

We probably need to port `elm-exploration/test` as well, so you can migrate your app’s tests to increase confidence. But that would probably also require forking the test runner to be able to run them. Sounds fun, but I’m not sure!

```sh
# gleam add elm@1
Not published!
```
```gleam
import elm/browser

pub fn main(args) {
  browser.element(
    init:,
    view:,
    update:,
    flags_decoder:,
    subscriptions:,
    effect_managers: [],
  )(args)
}
```

<!--
Further documentation can be found at <https://hexdocs.pm/elm>.
-->

## Status

Why I created this project:

- It was fun.
- To learn more about Elm’s internals.
- To learn more about Gleam FFI.
- _In case_ I need to port an Elm app to Gleam.

As you can see in the [Ported packages and modules](#ported-packages-and-modules) section, **there are a lot of packages and modules left to implement.** With the ones ported so far it’s possible to build a new, working Elm app, but it’s probably not enough to migrate an existing app.

Don’t expect me to finish this, or be around for fixing bugs. Do however feel free to report issues if you somehow end up trying this and run into something (because you probably will)! And ask me if you’d like to contribute.

## Differences

### Flags

Elm programs take _flags_ as input on initialization. In Elm, you write the _type_ for your flags, and the Elm compiler generates a decoder for that type (or gives an error message if it cannot generate a decoder for the type).

Since this is just Gleam package, not a compiler, we can’t do that. Instead, you need to write the flags decoder yourself and supply it to for example `browser.element`.

### Ports

In Elm, there is special syntax for defining a port. The compiler then generates functions for the ports that you can call, and sets the ports up.

Since this is just a Gleam package, not a compiler, we can’t do that. Instead, you need to use some extra port functions. Read more in the documentations for `platform.outgoing_port` and `platform.incoming_port`.

Note that ports might be over complicated in Gleam, which has FFI and allows side effects in functions. The port stuff exist to make porting an Elm app easier.

### Effect managers

Elm has something called _effect managers,_ but you might not have noticed, because only `elm/*` and `elm-explorations/*` packages can use them. The Elm compiler also sets up needed effect managers automatically, so regular Elm users have never had to think about them.

If you ever looked at the source code for some `elm/*` packages, you might have noticed that the first line says `effect module` instead of just `module`. Such a module can define an effect manager.

Since this is just a Gleam package, not a compiler, we can’t do effect manager stuff automatically. There are two things of note here:

- `effect module`s need to call one additional function instead of just exposing certain functions. That function returns the effect manager.
- You need to import the effect managers you need (for example `time.manager`) and pass them to for example `browser.element`. Otherwise you’ll get a runtime error (if you use for example `time.every`).

Note that the effect manager stuff isn’t hidden in this Gleam package, so if you’ve always had a weird craving for it, you can go nuts creating your own effect manager.

### Debugger

In Elm, you can use the `--debug` CLI flag to turn on the debugger.

Since this is just a Gleam package, not a compiler, we can’t do that. Instead, you need to change for example `browser.element` to `debugger.element` and add `import elm/debugger`. That’s what the Elm compiler does behind the scenes when you use the `--debug` flag!

### Compiled JS

The Elm compiler creates a single `.js` file, which defines `window.Elm` where you can access your apps. You can do for example `window.Elm.Main.init({ flags: {} })` to initialize an app.

The Gleam compiler creates a folder with a bunch of `.mjs` files, which import each other using the `import` and `export` syntax. You need to `import` your Elm programs and call them. For example, `import { main } from './path/to/main.mjs'; main({ flags: {} })`.

### Packages

The Elm compiler can install packages from [package.elm-lang.org](https://package.elm-lang.org/).

When porting an Elm app to Gleam, you need to copy those packages to your own codebase, and translate them to Gleam.

The exception is all `elm/*` packages, which are included in this package.

### Argument order

In Elm, `a |> f b` pipes `a` as the _last_ argument of `f`. It is the same as `f b a`. (The more pedantic way of explaining it that `f b` is evaluated first, which partially applies `f` and returns a new function. That new function is then called with `a` by the `|>` operator.)

In Gleam, `a |> f(b)` pipes `a` as the _first_ argument of `f`. It is the same as `f(a, b)`. (Gleam does not have partial application. Instead, `|>` is special syntax and they decided to put the piped argument first.)

You can control where the piped argument goes with an underscore: `a |> f(b, _)` means `f(b, a)`.

In Elm, it’s common to put the “interesting” argument _last_ in functions, to allow for pipelining.

In Gleam, it’s instead common to put the “interesting” argument _first_ in function, to allow for pipelining with Gleam’s rules.

This means that if you translate Elm function one to one, your pipelines won’t compile.

So far, I’ve flipped some `map` and `and_then` functions around to the Gleam style. But I’m not sure that’s the best idea. It might be better to let all functions be, and simply have you add some `_` in pipelines. If we go with flipping functions to the Gleam style, we should document which functions have been flipped here, and go through _all_ functions to see which ones should be changed.

## Ported packages and modules

Key:

F Fully ported.  
P Partially ported.  
N Not started.  
X Port not planned.  
G This has a [similar Gleam module](#similar-gleam-modules).

| Package | Version | Module | Status | Comment |
|-|-|-|-|
|elm/browser|1.0.2\*|Browser|F||
|elm/browser|1.0.2\*|Browser.Dom|N||
|elm/browser|1.0.2\*|Browser.Events|N||
|elm/browser|1.0.2\*|Browser.Navigation|F||
|elm/bytes|1.0.8|Bytes|N||
|elm/bytes|1.0.8|Bytes.Encode|N||
|elm/bytes|1.0.8|Bytes.Decode|N||
|elm/core|1.0.5|Basics|P|G|
|elm/core|1.0.5|String|N|G|
|elm/core|1.0.5|Char|N||
|elm/core|1.0.5|Bitwise|N||
|elm/core|1.0.5|Tuple|N|G|
|elm/core|1.0.5|List|N|G|
|elm/core|1.0.5|Dict|N|G|
|elm/core|1.0.5|Set|N|G|
|elm/core|1.0.5|Array|F|No arrays out of the box in Gleam.|
|elm/core|1.0.5|Maybe|N|G|
|elm/core|1.0.5|Result|N|G|
|elm/core|1.0.5|Debug|X|Use `echo`, `todo` and `string.inspect` instead.|
|elm/core|1.0.5|Platform.Cmd|F||
|elm/core|1.0.5|Platform.Sub|F||
|elm/core|1.0.5|Platform|F||
|elm/core|1.0.5|Process|F||
|elm/core|1.0.5|Task|F||
|elm/file|1.0.5|File|N||
|elm/file|1.0.5|File.Select|N||
|elm/file|1.0.5|File.Download|N||
|elm/html|1.0.0\*|Html|F||
|elm/html|1.0.0\*|Html.Attributes|F||
|elm/html|1.0.0\*|Html.Events|F||
|elm/html|1.0.0\*|Html.Keyed|F||
|elm/html|1.0.0\*|Html.Lazy|F||
|elm/http|2.0.0|Http|N||
|elm/json|1.1.3|Json.Decode|F||
|elm/json|1.1.3|Json.Encode|F||
|elm/parser|1.1.0|Parser|N||
|elm/parser|1.1.0|Parser.Advanced|N||
|elm/project-metadata-utils|1.0.2|Elm.Docs|X||
|elm/project-metadata-utils|1.0.2|Elm.Project|X||
|elm/project-metadata-utils|1.0.2|Elm.Error|X||
|elm/project-metadata-utils|1.0.2|Elm.Type|X||
|elm/project-metadata-utils|1.0.2|Elm.Module|X||
|elm/project-metadata-utils|1.0.2|Elm.Package|X||
|elm/project-metadata-utils|1.0.2|Elm.Version|X||
|elm/project-metadata-utils|1.0.2|Elm.Constraint|X||
|elm/project-metadata-utils|1.0.2|Elm.License|X||
|elm/random|1.0.0|Random|N||
|elm/regex|1.0.0|Regex|N||
|elm/svg|1.0.1|Svg|N||
|elm/svg|1.0.1|Svg.Attributes|N||
|elm/svg|1.0.1|Svg.Events|N||
|elm/svg|1.0.1|Svg.Keyed|N||
|elm/svg|1.0.1|Svg.Lazy|N||
|elm/time|1.0.0|Time|P||
|elm/url|1.0.0|Url|F||
|elm/url|1.0.0|Url.Builder|N||
|elm/url|1.0.0|Url.Parser|N||
|elm/url|1.0.0|Url.Parser.Query|N||
|elm/virtual-dom|1.0.4\*|VirtualDom|F||

\* The versions marked with an asterisk are actually based on the versions from the [elm-safe-virtual-dom](https://github.com/lydell/elm-safe-virtual-dom) project. So it’s the noted version plus the changes from `elm-safe-virtual-dom`.

### Similar Gleam modules

This refers to the modules marked with G in the above table.

- Basics: Gleam probably already has most of this, so no need to port it all. I think.
- String: The idea is to use Gleam’s strings instead of defining a new type for Elm `String`. We probably need to port some or all functions in the `String` module though, since Gleam’s `string` module isn’t identical, to make migration easier.
- Tuple: The idea is to use Gleam’s tuple syntax (`#(a, b)`) instead of defining `Tuple` and `Triple` types. We might need to port some functions in the `Tuple` module to make migration easier.
- List: The idea is to use Gleam’s list syntax (the same as Elm’s) instead of defining a new `List` type. We might need to port some functions in the `List` module to make migration easier.
- Dict: The idea is to use Gleam’s `Dict` type (identical to Elm’s, except keys aren’t restricted to `comparable`) instead of defining a new `Dict` type. We might need to port some functions in the `Dict` module to make migration easier.
- Set: The idea is to use Gleam’s `Set` type (identical to Elm’s, except keys aren’t restricted to `comparable`) instead of defining a new `Set` type. We might need to port some functions in the `Set` module to make migration easier.
- Maybe: The idea is to use Gleam’s `Option` type (uses `Some` and `None` instead of `Just` and `Nothing`) instead of defining Elm’s `Maybe` type. We might need to port some functions in the `Maybe` module to make migration easier.
- Result: The idea is to use Gleam’s `Result` type (identical to Elm, except it’s `Result(ok, error)` instead of `Result error ok` – the type parameters are flipped) instead of defining a new `Result` type. We might need to port some functions in the `Result` module to make migration easier.

I think things will be less confusing if we use the built-in Gleam types instead of defining new, almost identical ones.

## Development

Build:

```
gleam build
```

Then serve the repo root with a static file server. There are example apps to test with in the `dev/` folder.
