#!/bin/dsl

app
  [ capability "core/io" ( StdIn, StdOut )
  , capability "core/net" ( NetRead, NetWrite ) # @NetRead, @NetWrite?
  ]
  { main = main
  , configure = configure
  # implicit import "core/prelude"
  #, prelude = "core/prelude" # TODO: Implicit prelude configurable?
  }

import "core/platform/cli"
  # # TODO: is Enum/Flag etc. too much magic and even necessary?
  # type ExitCode
  #   | Ok as Truthy, Enum(0)
  #   | Error as Enum(1)
  | ExitCode
    ( Ok as CliOk
    , Error as CliError
    )
import "core/io/stdout" as stdout
import "core/date" as date
  | Instant
import "core/lang/boolean" as boolean # TODO: Boolean logic operators?
import "core/codec" as codec
  # Used by JSON or other transports
  # Traits/Abilities/...
  # Serializable?
  # Parseable?
  | Codec
import "core/net"
  | Url(Url)
import "core/net/http" as http
  # Only types can be exposed, functions and constants need to be qualified like in Go
  | HttpRequest
  | HttpStatus(HttpOk)
import "core/codec"
  | Codec
  | Opaque
import "core/codec/json" as json
import "core/web/console" as console
  # `console` access needs StdOut capability
import "core/web/html" as html
import "core/math" as math

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
  | HttpStatus as LegacyHttpStatus
    ( ImATeapot as LegacyImATeapot
    )

type Mode =
  | Production
  | Development
  | Testing

record AppConfig =
  { externalApi : Url
  , api : Url
  , mode : Mode
  }

#configure : Key, Opaque -> Result AppConfig [ DecodeError ]
configure : Capability, Opaque -> Result AppConfig [ Incapable ]
function configure capability opaque =
  # "capability" is just the basic capability to run this init code and
  # nothing more. So you can't just launch rockets while initializing an app
  task.attempt
    { run ->
      when run cap (opaque |> codec.decode json.codec) is
        | json ->
          { externalApi = Url json."external-api"
          , api = Url json.api
          , mode =
            when json.mode is
              | "production" -> Production
              | "test" -> Testing
              | else -> Development
          }
        | else ->
          { externalApi = Url "https://anapioficeandfire.com/api/characters/"
          , api = Url "https://our.own.api/"
          , mode = Production
          }
    }

# Capabilities can be attached to Custom Type constructors and then
# be used when performing side-effects. The resulting subsystem that
# abstracts the platform is then literally incapable of escalating
# what is declared.
# TODO: It would be nice, if we could constrain capabilities even further
# when delegating sub-tasks somewhere else in the codebase, how do we
# do that, library code shouldn't have access to ambient app config?
# TODO: How to access "ambient" configuration?
type Untrusted =
  | Untrusted with ( NetRead app.externalApi )

type Trusted =
  | Trusted with ( StdIn, StdOut, NetRead app.api, NetWrite app.api )



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
# TODO: Do we need "function" keyword? It kind of clashes with the types visually
addOne : Int64 -> Int64
function addOne x =
  x + 1

addTwo : Decimal -> Decimal
let addTwo = { it + 2.0 }

# TODO: Is this the same function as addOne because the implementation(?) is the same??
#       so `equals addOne plusOne` should be Truthy??
function plusOne k =
  k + 1


# TODO: Is this equivalent to addOne?
function onePlus a =
  1 + a

# TODO: "Polymorphic" records?
record Point2d a =
  { a as Number
  | x : a
  , y : a
  }

# TODO: Record fragments can actually change type as opposed to ... on records?
record Point3d is Point2d Decimal =
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
function withAttribute _ =
  # This should never happen
  expect.todo "This function hasn't been implemented"
  # TODO: panic/crash?

# TODO: Functions without argument need to represent that in the type, do we need Unit?
printSomething: _ -> Result _ [ StdoutError ] { Stdout }
function printSomething _ =
  task.attempt
    { run -> run (stdout.println "Evil side-effect in lambda???")
    }

# TODO: "Getter functions" is not a very obvious and useful thing, do we even allow this?
let returnTheQuestion = { "You know nothin'" }

record SomeDataFragment =
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

# IO side effects via console.log
# TODO: find nice way to work with sequences but keep it open to use something else
#sig main : Sequence String -> IO ExitCode
main : Sequence String -> ExitCode { NetRead, Stdout }
#let main = args ->
function main args
  requestJonSnow : HttpRequest
  let requestJonSnow = callAnApiOfIceAndFire 583

  result : Result ExitCode [ StdoutError ]
  let result = task.attempt
    { try ->
      # Lambdas can have multiple let expressions that we can "abuse" for
      # nice do-notation. It's even easily extensible because it's not syntax
      # but just library code
      let raw = try Untrusted requestJonSnow
      let json = try Untrusted (raw |> codec.decode json.codec)
      when json is
        | Ok hero ->
            """
            # Inline assertions only run in specific environments, if there is a comment
            # attached to the expression it'll be shown on failure
            """
            expect hero.url == "https://anapioficeandfire.com/api/characters/583"
            # Should've been Jon Snow
            expect hero.name == "Jon Snow"
            expect hero.culture == "Northmen"
            CliOk
        | Error NotFound ->
            try Trusted (stdout.println "Jon Snow not found")
            CliError
        | _ -> CliError
    }
  let exitCode =
    when result is
      | Ok code -> code
      | _ -> Error

  let nums = [1, 2, 3]
    |> sequence.map { x -> x * 2 }
    |> sequence.map { it+3 }
  # TODO: Eq "typeclass" for sequences?
  # expect [2, 5, 10] == nums
  expect (sequence.equals [2, 5, 10] nums)

  # TODO: Operators on Number, Int, Decimal, ...?
  let four = 2 |> { it*it }
  expect 4 == four

  let ret = when args is
    | [name, version] where "1.0.0" == version -> Ok
    | [name, ...rest] ->
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


type Msg =
  | ClickSth

type Cmd msg =
  | DoSomething msg

# Function syntax shorter, or with let or with function?
update : State, Msg -> Tuple (Cmd Msg) State
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

record RawAttr =
  { key
  , value
  }

type RawTag =
  | html
  | head
  | title
  | body
  | meta

type TextContent =
  | Text String
  | Missing

record RawNode =
  { attributes: Sequence RawAttr
  , children: Sequence RawNode
  , tag: RawTag
  , textContent: TextContent
  }

type Node =
  | Node

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
