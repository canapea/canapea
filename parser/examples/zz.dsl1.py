#!/bin/dsl

app with
  { platform = "core/platform/cli"
  , main = main
  # implicit import "core/prelude"
  #, prelude = "core/prelude" # TODO: Implicit prelude configurable?
  , capabilities =
    # If you don't request access the program can do no side-effects whatsoever
    [ NetRead("https://anapioficeandfire.com/api/characters/*")
    , Stdout
    ]
  }
  #| publicConstant
  #| main

import "core/platform/cli"
  | ExitCode(Ok, Error(..))
  # # TODO: is Enum/Flag etc. too much magic and even necessary?
  # type ExitCode
  #   | Ok as Truthy, Enum(0)
  #   | Error as Enum(1)
import "core/platform/cli/stdout" as stdout

import "core/date" as date
import "core/lang/boolean" as boolean

import "core/http" as http
  # Only types can be exposed, functions and constants need to be qualified like in Go
  | HttpRequest
  | HttpStatus(..) # TODO: Bulk expose type constructors?

# Importing the same module in different versions is totally fine
# TODO: Importmaps with readable names should be a thing in DSLON format
# # config.dsl
# let packages = 
#   { "core/http@legacy" =
#     { url = "https://github.com/dsl/core/http/0.7.1"
#     }
#   }
# { packages
# }
import "core/http@legacy"
  | HttpStatus as LegacyHttpStatus(ImATeapot as LegacyImATeapot)

# Used by JSON or other transports
import "core/codec" as codec
  # Traits/Abilities/...
  # Serializable?
  # Parseable?
  | Codec

import "core/json" as json

import "core/web/console" as console

import "core/web/html" as html

import "core/math" as math

#let stdout = cli.stdout

"""
# primitive Decimal as Number
expect 42 == theAnswer
"""
let theAnswer = 42 # Int64 by default?
let billion = 1_000_000_000 # Separators make sense
let pi = 3.14159 # Decimal by default
let piAsFloat = float.fromDecimal pi # We don't encourage IEEE Floating Point weirdness

"""
# Documentation comment with example that's checked
expect (addOne 1) == 2
expect (addOne 41) == 42
"""
addOne : Int64 -> Int64
function addOne x
  x + 1

addTwo : Decimal -> Decimal
let addTwo = { it + 2.0 }

# TODO: Is this the same function as addOne because the implementation(?) is the same??
#       so `equals addOne plusOne` should be Truthy??
function plusOne k
  k + 1


# TODO: Is this equivalent to addOne?
function onePlus a
  1 + a


record Point2d a 
  { a as Number
  | x : a
  , y : a
  }

# TODO: Record fragments can actually change type as opposed to ... on records?
record Point3d is Point2d Decimal
  { z : Decimal
  }


# TODO: Named args should not be an issue with record destructuring
vectorLength : Point3d -> Decimal
let vectorLength =
  { { x, y, z } ->
    math.squareRoot (x*x + y*y + z*z)
  }


# TODO: @attribute decorators?
"""
@deprecated
"""
@deprecated
function withAttribute
  # This should never happen
  expect.todo "This function hasn't been implemented"
  # TODO: panic/crash?

#let askForJonSnow = () ->
#  let id = 583
#  # ...
# TODO: Functions without argument need to represent that in the type, do we need Unit?
askForJonSnow : () -> () { Stdout } [ StdoutError ]
let askForJonSnow = { stdout.println "Evil side-effect in lambda???" }

# TODO: "Getter functions" is not a very obvious and useful thing, do we even allow this?
let returnTheQuestion = { "You know nothin'" }

# Has algebraic side effects via http.get but is pure since it's only data
callAnApiOfIceAndFire : Int32 -> HttpRequest
let callAnApiOfIceAndFire =
  { http.get `https://anapioficeandfire.com/api/characters/${it}`
  }
  ##let id = 583
  #let url = `https://anapioficeandfire.com/api/characters/${id}`
  ##let url = "https://anapioficeandfire.com/api/characters/``id``"
  ##let url = $"https://anapioficeandfire.com/api/characters/${id}"
  ##let url = $"https://anapioficeandfire.com/api/characters/{{id}}"
  ##http.get url

type Mode
  | Production
  | Development
  | Testing

conditionals : String -> Mode
let conditionals =
  { when it is
    | "production" -> Production
    | "test" -> Testing
    | else -> Development
  }


record SomeDataFragment
  { hello : String
  , world : String
  , today : Instant
  }

# record
# TODO: record update via `with` or sth. similar?
let someData =
  { hello = "Hello"
  , world = "World"
  , "the-answer" = 42
  , "tree-root" =
    { value = 42
    , children =
      [ { value = 142
        }
      , { value = 942
        }
      ]
    }
  , today = date.instant "2025-04-11T12:00"
  }

# TODO: record extensions or just filling in other values that are already known?
let someDataCopy =
  { ...someData
  , world = "OMG"
  , "evil-extra-property" = "BOOOOOM!" # won't work
  }


# IO side effects via console.log
# TODO: find nice way to work with sequences but keep it open to use something else
#sig main : Sequence String -> IO ExitCode
main : Sequence String -> ExitCode { NetRead, Stdout }
#let main = args ->
function main args
  let requestJonSnow = callAnApiOfIceAndFire 583
  #let result = do {
  #  let hero <- requestJonSnow |> codec.decode json.codec
  #}
  #let result <- requestJonSnow |> codec.decode json.codec
  #let ret = task.attempt (requestJonSnow |> codec.decode json.codec) {
  #  when it is
  #    | Ok(hero) -> Ok
  #    | else -> Error
  #}
  #let result = task.attempt (requestJonSnow |> codec.decode json.codec)
  result : Result ExitCode [ StdoutError ]
  let result = task.attempt {
    run ->
      # Lambdas can have multiple let expressions that we can "abuse" for
      # nice do-notation. It's even easily extensible because it's not syntax
      # but just library code
      let raw = run requestJonSnow
      let json = run (raw |> codec.decode json.codec)
      when json is
        | Ok(hero) ->
            """
            # Inline assertions only run in specific environments, if there is a comment
            # attached to the expression it'll be shown on failure
            """
            expect hero.url == "https://anapioficeandfire.com/api/characters/583"
            # Should've been Jon Snow
            expect hero.name == "Jon Snow"
            expect hero.culture == "Northmen"
            Ok
        | Error(NotFound) ->
            stdout.println "Jon Snow not found"
            Error
        | else -> Error
  }
  let exitCode =
    when result is
      | Ok -> result
      | else -> Error
  #let result = do {
  #  task.attempt requestJonSnow {
  #    raw -> task.attempt (raw |> codec.decode json.codec) {
  #      json -> when json is
  #        | Ok(hero) -> Ok
  #        | else -> Error
  #    }
  #  }
  #  let raw <- requestJonSnow
  #  let json <- raw |> codec.decode json.codec
  #  when json is
  #    | Ok(hero) ->
  #        expect hero.name == "Jon Snow"
  #        Ok
  #    | else -> Error
  #}
  #let ret = when result is
  #  | Ok(hero) ->
  #      """
  #      # Inline assertions only run in specific environments, if there is a comment
  #      # attached to the expression it'll be shown on failure
  #      """
  #      expect hero.url == "https://anapioficeandfire.com/api/characters/583"
  #      # Should've been Jon Snow
  #      expect hero.name == "Jon Snow"
  #      expect hero.culture == "Northmen"
  #      Ok
  #  | Error(NotFound) ->
  #      stdout.println "Jon Snow not found"
  #      Error
  #  | else ->
  #      Error

  let nums = [1; 2; 3]
    |> sequence.map { x -> x * 2 }
    |> sequence.map { it+3 }
  expect [2; 5; 10] == nums

  let four = 2 |> { it*it }
  expect 4 == four

  let ret = when args is
    | [name; version] where "1.0.0" == version -> Ok
    | [name; ...rest] ->
      when name is
        | "dsl" -> Ok
        | else -> Error
    | else -> Error
  
  # TODO: builder seem neat but is it worth the complexity?
  let htmlBuilder?? =
    with html {
      head {
        meta(charset="utf-8") {}
        title { text "Some title" }
      }
      body { text "Hello, World!" }
    }
  let jsonBuilder?? =
    with json {
      some {
        arr = ["one", "two", "three"]
      }
    }
  let ordinaryAnonymousRecord =
    { some =
      { arr = [ "one", "two", "three" ]
      }
    }

  exitCode



module "core/web/html" as TreeBuilder(Node, RawNode)
  | Node
  | text
  # builder interface?
  | createNode
  | appendChildNode


type Msg
  | ClickSth

type Cmd msg

# Function syntax shorter, or with let or with function?
update : State, Msg -> Tuple(Cmd Msg, State)
update state msg =
  when msg is
    | ClickSth = tuple.new cmd.none { ...state }
#fn update state msg
#function update state msg
#let update =
#  { state, msg ->
#    when msg
#      | ClickSth = tuple.new Cmd.none { ...state }
#  }



record RawAttr
  { key
  , value
  }

type RawTag
  | html
  | head
  | title
  | body
  | meta

type TextContent
  | Text(String)
  | Missing

record RawNode
  { attributes: Sequence RawAttr
  , children: Sequence RawNode
  , tag: RawTag
  , textContent: TextContent
  }

type Node

function createNode raw 
  let { attributes, children, tag, textContent } = raw
  expect.todo

function appendChildNode node child
  expect.todo

function body { children }
  expect.todo


function text t
  expect.todo


#
# 2025-04-11
# ==========
#
# * minimal syntax
# * expression based
# * kotlin lambda syntax
# * no extra syntax for tuples, only 4-tuples allowed
#   * elm tuples? max size tuples?
#   * only records, no tuples?
# * config is just language syntax DSLON
# * docker support?
# * structural equality
# * no string concat operator! Use library function or interpolation instead
# * do notation for callback hell?
# * no auto-currying
# * recursion? loops?
# * pattern matching guards
# * pattern matching fragment naming?
# * no unit support!
# * scientific numbers? hex/binary/octal literals?
# * println etc. via platform
# * good date support! but maybe just as library
# * one way to do things
# * no bulk imports!
# * operators as function calls!
# * no custom operators!
# * last expression is return value
# * side effects as data with platform executing stuff!
# * lazy/greedy?
# * code as data? LISP is neat but not necessarily nice to look at
# * macros?
# * language editions?
# * capability security! Fine grained, NetRead("https://the.allowed.url/path/*")
# * traits/roc abilities?
# * ML type inference!
# * nice VCS diffs!
# * string representation?
# * CRDT?
# * gentlate?
# * number formats! In64, Decimal as default everything else can be tedious
# * documentation! not sure yet how
# * pre/post conditions, code contracts?
# * roc auto resolve serialization on usage
# * roc platforms (kind of framework) with abilities with sandboxing
# * memory model?
# * green threads?
# * no ffi interop in the language, only platform has access to ffi stuff!
# * no sideeffects outside of platform!
# * roc sideeffect collection in error handling, only a "crash" function, everything else is data
# * no boolean blindness (nobody does this but I like it)
# * roc Tests/assertions in code only run in debug/test but always up-to-date docs
# * clj import from any place, dependencies on function level, not package level
# * easy to read core library, no abbreviations
# * roc, gleam, pipe operator! no auto-currying, weird at first but works more like people expect it to
# * first program is language server?
# * specification of language like WASM SpecTech completely defined and automated?
# * distributed like Unison lang?
# * unison names of functions are "optional", type is the ID?
#   -> function == function?
# * coroutine like GO?
# * roc async with postfix "!"?
# * auto async?
# * threading?
# * actor model like erlang?
# * BEAM VM as backend/platform?
# * JS/WASM as backend?
# * autofmt without config!
# * package platform with easy changes
# * packages with auto semantic versions? Does that make sense for the function level dependencies?
#
