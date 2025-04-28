# Canapea

Welcome to the home of the Canapea Programming Language

> [!IMPORTANT]
> The language is in very early design phase, consult the [preliminary roadmap](#roadmap) for where we're at.


## Vision

The current vision is an easy to learn pure, safe, eagerly evaluated statically typed functional language at its core, with a friendly compiler to guide the user, only leveraging algebraic side-effects that are then implemented by the chosen platform "under the hood". This design closely follows the guiding principles of [Elm](https://elm-lang.org) and [Roc](https://roc-lang.org), taking inspiration from various other languages.

What makes Canapea special is that it wants to get rid of as many pitfalls that exist in most other languages by its very construction. The goal is that there should be one way to do things. The language comes "batteries included" with a formatter, that isn't configurable. Numbers should work like they do "in normal life", leaving IEEE Floating Point weirdness to those who really want or need to deal with them. Data modeling should be done with algebraic data types so the language will try to only include features that direct the user to that [pit of success (external link)](https://blog.ploeh.dk/2023/03/27/more-functional-pits-of-success/). There will be no way to model `null` as a blanket concept, no indescript `Maybe`/`Option`/`Left`/`Right`/... containers. If something can fail there is the `Result(Ok, Error)` type and missing values are best modeled in the domain language using algrebraic data types.

The code would look something like this:

```python
# Obligatory "Hello, World" app

app with
  [ capability "core/io" ( StdOut )
  ]
  { main = main
  }


import "core/io/stdout" as stdout
import "core/io/platform/cli"
  exposing
    | ExitCode
      ( Ok as CliOk
      , Error as CliError
      )


main : Sequence String -> ExitCode { Stdout }
function main args =
  task.attempt
    { run ->
        when run (stdout.println "Hello, World!") is
          | Ok _ -> CliOk
          | _ -> CliError
    }

```

## Roadmap

| Step | Done | Status |
|------|------|--------|
| [Implement language parser](https://github.com/orgs/canapea/projects/1/views/1) | [ ] | ![Parser Workflow](https://github.com/canapea/canapea/actions/workflows/parser.yml/badge.svg)
| [Make Syntax highlighting work](https://github.com/canapea/canapea/issues/33) | [x] | [🚧 Ticket #33](https://github.com/canapea/canapea/issues/33)
| [VSCod{e,ium} Extension](https://github.com/orgs/canapea/projects/2/views/1) | [ ] | [![Language Support Workflow](https://github.com/canapea/canapea/actions/workflows/vsext.yml/badge.svg)](https://github.com/canapea/canapea/actions/workflows/vsext.yml)
| [Implement basic command line interface](https://github.com/orgs/canapea/projects/3/views/1) | [ ] | [![CLI Workflow](https://github.com/canapea/canapea/actions/workflows/cli.yml/badge.svg)](https://github.com/canapea/canapea/actions/workflows/cli.yml)
| Implement basic language server | [ ] |
| Implement basic platform with necessary capabilities for command line apps | [ ] |
| Make command line apps work inside a browser for a playground | [ ] |
| Pin language design for dynamic language v0.1.0 | [ ] |
| Design type system for dynamic language v0.1.0 | [ ] |
| Implement type inference for statically typed language v0.2.0 | [ ] |
| Make the compiler a jolly cooperator | [ ] |
| ... |    |


## Sub Projects


<details>
  <summary>Sub-Project High-Level Summary</summary>

### [Parser](./parser/)

The language parser is generated with the help of tree-sitter. For technical details consult its [README](./parser/README.md).

### [VSCod{e,ium} Extension](./language-support-vscode/)

The official VSCod{e,ium} extension. For technical details consult its [README](./language-support-vscode/README.md).


</details>

