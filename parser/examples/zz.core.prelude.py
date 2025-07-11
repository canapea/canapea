## Module declaration syntax variants

module "format"

module "system/format"
  expose
    | format

module "sys/format"
  expose
    | format

module "canapea/format"
  expose
    | format

module org.canapea.core/lang
  exposing
    | Eq
    | Truthy
    | Falsy
  bindings (fn, const)

(module org.canapea.core/lang
  (types Eq Truthy Falsy)
  (bindings fn const))

module (core) "lang"

let <module> org.canapea.core.lang =

type (module) org.canapea.core.lang =
  { T ->
    let x = "x"
    x
  }

#(package org.canapea.core.lang)
#  module (Eq Truthy Falsy) (someFunction constant)
# type canapea.lang = module (Eq Truthy Falsy) (someFunction constant)


import "canapea/sequence" as seq
  exposing
    | Sequence as Seq
import "canapea/experimental/compiletime" as comptime
import "experimental/datatypes/uint"
  exposing
    | Uint8 as U8


# let format : String, _ -> String
let format : Seq U8, _ -> Seq U8
let format str args =
  # This should never happen
  assert.unreachable
  assert.invariant 1 == 1
  assert 1 == 1
  debug.todo _
  expect 1 == 1

  # let kvs = comptime.infer args
  # let len = seq.length str

  # let xform = comptime.module
  #   {
  #   }
  # let x =
  #   seq.transduce coll xf f
  # let x =
  #   seq.mapWithIndex
  #     str
  #     { c i ->
  #       when c is
  #       | "{" ->
  #         let j = seq.findWithIndex { seq.at "}" it }
  #         # FIXME: transducers!
  #         # seq.mapWithIndex
  #         #   (seq.range str (i+1) (len-1))
  #         #   { cc j ->
  #         #     yield
  #         #   }
  #         #   # let y = seq.at str (i+1)
  #       | else a -> [a]
  #     }
  # for c of str
  #   when c of
  #     | "{" ->
  #     | else a -> [a]
  # for [k, v] of kvs
        # |> seq.map
        #   { [k, v] ->
        #     []
        #   }
  # seq.map { [key, val] ->  }
  #   |>
  # while [key, value] of comptime.entries arg

expect (format "Hello, {s}!" (tuple "World"))
expect (format "LOG[{s}] {s} - {s}!" (tuple "INFO" "2025-07-11T07:00:00Z" "Logmessage for this entry"))
expect format
    "LOG[{level:s}] {date:s} - {msg:s}\n"
    { level = "INFO"
    , date = "2025-07-11T07:00:00Z"
    , msg = "Logmessage for this entry"
    }
expect format "LOG[{1:s}] {2:s} - {3:s}\n" {1="INFO",2="2025-07-11T07:00:00Z",3="Logmessage for this entry"}
expect format "LOG[{a:s}] {b:s} - {c:s}\n" {a="INFO",b="2025-07-11T07:00:00Z",c="Logmessage for this entry"}
expect format "LOG[{:s}] {:s} - {:s}\n" {"INFO","2025-07-11T07:00:00Z","Logmessage for this entry"}
expect formatPick { {a,c} -> [ "This is a ", fmt.s a, " in the context of ", fmt.s c ] } {a="A",b="B",c="C"}
  { let a = "A"
    let b = "B"
    format ["This is a ", s a, " in the context of ", s b]
  }


# TODO: Modules as builders?

module "experimental/tests"

import "experimental/task/builder" as task

task.attempt
  { run ->
    run Out (stdout.writeLine "Hello, World!")
  }


module "experimental/format/builder"
  exposing
    | build

let build fn =



###cns.^

module "lang"
  exposing
    | Eq
    | Truthy
    | Falsy
    | Result(..)
    | const
    | fn
    #??| ...result

let "lang" = module

let lang = module "lang"

let div : Int, Int -> Result Int [_]
let div x y =
  when y.equals 0 is
    Ok _ -> error.DivisionByZero
    else -> x / y

function f0 : Int, Int -> Int
function f0 x y =
  int.+ x y

decl f1 : Int, Int -> Int
defn f1 x y =
  int.+ x y

def f2 : Int, Int -> Int
let f2 x y =
  int.+ x y

let f3 : Int, Int -> Int
let f3 x y =
  int.+ x y

let f4 : Int, Int -> Int
let f4 = { x y -> int.+ x y }

fun f5 : Int, Int -> Int
fun f5 x y =
  int.+ x y

fn f6 : Int, Int -> Int
fn f6 x y =
  int.+ x y

let f7 : Int, Int -> Int
let f7 =
  { x y ->
    int.+ x y
  }

let f8 : Int, Int -> Int
let f8 = { int.+ $1 $2 }

let f9 : Int, Int -> Int
let f9 = { x y ->
  int.+ x y
}

application

import capability "canapea/io"
  exposing
   | StdOut
import capability "canapea/net"
  exposing
   | HttpGet
   | HttpPost

import "canapea/codec" as codec
  exposing
    | EncodedValue
import "canapea/codec/json" as json
import "canapea/format" as fmt
import "canapea/io/cli" as cli
  exposing
    | CliExitResult(CliOk, CliError)
import "canapea/io/stdio" as stdio
  # exposing
  #   | StdIo(StdOut)
import "canapea/lang/result" as result
  exposing
    | Result(Ok, Err)
# import "canapea/net"
#   exposing
#     | HttpMethod(HttpGet, HttpPost)
#import "canapea/number"
#  exposing
#    | @

"""md
# Module Config

This is sample code for supplying some json configuration
but you could also use an .ini file or a protobuf.

Configuration is considered part of compilation time.
This means that `module config` can fail with Result(Err)
but this will terminate the program instantly because you
need to supply actual values that will be available as
`module.config` to the rest of this module.

It's part of the application definition so you can use
imports but none of your custom capabilities so this gives
every program a baseline to produce static configuration
on which you can build in your main.

This is different from reading e.g. command line args at
runtime.
"""
application config
  { value -> # run, capability?
      # Module Metdata
      let meta : { name : String, package : String }
      let meta = module

      # Decode configuration
      let config : Result _ [InvalidJson]
      let config = codec.decode (json.codec value)

      # Error propagation is transitive, if anything here is Result(Err)
      # the program does not start
      { config
      # You can supply a main function of your choice depending on the
      # supplied configuration
      , main = cliMain
      }
      # when config is
      #   | Ok c -> c
      #   | else err -> CliError 1 err
      # let config = codec.decode cli.argsCodec value
      # yield config
      # yield capability.Api
      #   [ @HttpGet "https://anapioficeandfire.org"
      #   , @HttpPost fmt.format "{s}/log" config.ourApi # "https://our.api"
      #   ]
      # yield capability.Out [ @StdOut ]
      # { config = config
      # { config = use config otherwise
      #     | err -> CliError 1 err
      # , capabilities =
      #   [ capability.Api
      #     [ @HttpGet "https://anapioficeandfire.org"
      #     , @HttpPost fmt.format "{s}/log" config.ourApi # "https://our.api"
      #     ]
      #   , capability.Out [ @StdOut ]
      #   ]
      # , main = main
      # }
      #{ main = main
      #}
      #main = main
      #where config
  }

type Cap =
  | Api is
    [ @HttpGet "https://anapioficeandfire.org"
    , @HttpPost (fmt.format "{s}/log" application.config.ourApi) # "https://our.api"
    ]
  | Out is [ @StdOut ]

type MainCap =
  | ProgramFailure FailureVariant is [ @Panic ]
  | RunPureCode
  | RunImpureCode

type FailureVariant msg =
  | CompilerBug msg
  | TerminatedByOs msg
  | Canceled msg
  | InvariantViolated msg
  | UnidentifiedFailure msg

type RecoveryStrategy =
  | Panic
  # | Retry
  # | ...?


let cliMain : _ -> CliExitResult {Out,+ProgramFailure,+RunPureCode,+RunImpureCode}
let cliMain config =
  task.perform
    { run ->
      let msg = fmt.format "Hello, {s}" config.who
      # when run Out (stdout.writeLine msg) is
      #   | Ok _ -> CliOk
      #   | else err -> CliError 1 err
      use run Out (stdout.writeLine msg) otherwise
        | error.WriteFailed -> CliError 2 _
        | else err -> CliError 1 err
    }

type Result a err =
  | Ok a is [ @Success ]
  | Err err is [ @Failure ]


type constructor concept Result a err =
  #???

# type capability Api is
#   [ @HttpGet "https://anapioficeandfire.org"
#   , @HttpPost "https://our.api/log"
#   ]
# type capability Out is [ @StdOut ]


type Cap =
  | Api is [ @HttpGet "https://anapioficeandfire.org", @HttpPost "https://our.api/log" ]
  | Out is [ @StdOut ]

# module "asoiaf"
#   exposing
#     | findCharacterByName
#     | fetchCharacterById
import "asoiaf" as asoiaf

let fetchCharacter {Api} : String -> Result EncodedValue [_]
#let fetchCharacter {Api} : String -> Result EncodedValue [BadRequest, NotFound, ServerError]
#let fetchCharacter ! ServerError, NotFound
let fetchCharacter name =
  task.perform
    { run ->
      let id = run Api (asoiaf.findCharacterByName name)
      let json = run Api (asoiaf.fetchCharacterById id)
      json
      #when json is
      #  | Err NotFound -> error.CharacterNotFound
      #  | else rest -> rest
      #json orelse error.Unknown
      #when json is
      #  | Ok _ -> json
      #  | Err _ -> error.Unknown
    }

let greetJonSnow : Cap{Api,Out} ->  Result (Seq String) []
let greetJonSnow cap =
  # Look ma, usage based JSON decoding
  let ygritte = fetchCharacter cap.Api "Ygritte"
  let { name, quotes } = codec.decode json.codec ygritte
  let quote = Seq.find { String.startsWith it "You know noth" }
  #           ^- quotes must be a sequence
  #                                        ^- and they get compared to String
  let line =
    when quote is
      | Ok s -> fmt.format "{s}: {s}" name s
      #                               ^- name has to be a String because of the format
      | ItemNotFound, NotFound -> "Quote not found"
      | else msg -> unreachable "Something went horribly wrong" msg

  # effect.perform
  task.perform { run -> run cap.Out stdio.writeLine s }





type record X =
  { a : Nat
  , b : String
  , c : Decimal
  }

module "canapea/lang"
  exposing
    | Eq
    | Truthy
    | Falsy
  bindings
    | someFunction
    | constant

import "canapea/internal/stuff" as stuff
  exposing
    | Tttype
    | ZZzzz



module "core/prelude"
# TODO: capabilities + roc-like platforms that provide them
# TODO: what to do about custom capabilities?

# # TODO: type alias?
# type alias Args as Sequence String

# TODO: Inline modules for normal code?
# TODO: OCaml param modules?
module "greet"
  exposing
    | hello

function hello who =
  # FIXME: finally sensible interpolation without escaping stuff?
  $"""Hello, ${who}!"""
  fmt.format $$"Hello, {{who}}!" who

"""
# TODO: Support LISP syntax mode to as wire format?
(module greet (function hello [who] `Hello, ${who}!`))
"""


"""
# TODO: export | implicit import | transitive import
# TODO: user code mechanism to forward imports?
@transitive
"""
import "core/lang"
  exposing
    #| Unit
    | Result(..)
    | Truthy | Falsy | Enum # | Flag?
    # TODO: import syntax constructs sounds cool
    | (=) | (|>) | (:)
    | as | crash | expect | function | let | record | type | when

import "core/lang/boolean" as boolean

# Task needs implementation in platform
import "core/task" as task
  exposing
    | Task

import "core/sequence" as sequence
  exposing
    | Sequence | ([])

import "core/tuple" as tuple
  exposing
    | Tuple
    | Tuple3
    | Tuple4

import "core/string" as string
  exposing
    | String

import "core/math" as math

import "core/number"
  exposing
    | Number | (+) | (-) | (*) | modulo | divide

import "core/number/decimal"
  exposing
    | Decimal

import "core/number/int"
  exposing
    | Int64

import "core/number/float"
  exposing
    | Float64

import "core/date"
  exposing
    | Instant

#import "core/test/expect" as expect

# Http IO needs implementation in platform
import "core/http"


module "core/http"
  exposing
    | HttpStatus

type HttpStatus =
  | OK is [ Truthy, Enum 200 ]
  | Created is [ Truthy, Enum 201 ]
  | NotFound is [ Enum 404 ]
  | ServerError is [ Enum 500 ]


module "core/lang"
  exposing
    | Result
    # | Unit

type Result a err =
  | Ok a
  | Error err

# type Unit

