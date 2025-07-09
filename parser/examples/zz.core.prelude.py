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
  exposing
    | main

import "canapea/codec" as codec
import "canapea/codec/json" as json
  exposing
    | EncodedValue
import "canapea/format" as fmt
import "canapea/io/stdio" as stdio
  exposing
    | @StdOut
import "canapea/lang/result" as result
  exposing
    | Result(Ok, Err)
import "canapea/net"
  exposing
    | @HttpGet
    | @HttpPost
#import "canapea/number"
#  exposing
#    | @

module configuration
  { run cfg capability ->
      let config = run (code.decode json.codec cfg)
      { config = config
      , capabilities =
        [ capability.Api
          [ @HttpGet "https://anapioficeandfire.org"
          , @HttpPost fmt.format "{s}/log" config.ourApi # "https://our.api"
          ]
        , capability.Out [ @StdOut ]
        ]
      }
      #{ main = main
      #}
      #main = main
      #where config
  }


type Result a err =
  | Ok a is [ Success ]
  | Err err is [ Failure ]


type constructor concept Result a err =
  #???

type capability Api is
  [ @HttpGet "https://anapioficeandfire.org"
  , @HttpPost "https://our.api/log"
  ]
type capability Out is [ @StdOut ]


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

  task.perform { run -> run cap.Out stdio.writeLine s }





type record X =
  { a : Nat
  , b : String
  , c : Decimal
  }


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

