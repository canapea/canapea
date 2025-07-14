"""
#
# This is just pure brain dump for experimentation and api exploration
#
"""

module "experimental/very/very/experimental"


# TODO: export | implicit import | transitive import
# TODO: user code mechanism to forward imports?
@transitive
import "core/lang"
  exposing
    #| Unit
    | Result(..)
    | Truthy | Falsy | Enum # | Flag?
    # TODO: import syntax constructs sounds cool
    | (=) | (|>) | (:)
    | as | crash | expect | function | let | record | type | when

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
import "canapea/logging" as logging


let log : Sequence Uint8 -> _ {LogError}
let log = logging.newLog module.name


let fn : Sequence Uint8 -> _ {DebugOut}
let fn arg =
  debug.printf "{a:s}\n" {a=arg}


# Capabilities can be attached to Custom Type constructors and then
# be used when performing side-effects. The resulting subsystem that
# abstracts the platform is then literally incapable of escalating
# what is declared.
type Cap =
  | Out is [ StdOut ]


# let format : String, _ -> String
let format : Seq U8, _ -> Seq U8 {Out}
let format str args =
  log "{m:s}" {m="'format' function"}

  expect 1 == 1

  debug.stash
    console.printf "{s:s}\n" {s=str}
    console.printf "{i:s}{s:s}\n" {i=indent,s=str}

  let xf =
    seq.compose3
      seq.map { it + 1 }
      seq.filter { it % 2 == 0 }
      seq.map { it * 2 }

  let sum = [1,2,3] |> seq.transduce 0 xf seq.sum

  let another : Int
  let another =
    let _ = stdout.writeLine Out "x"
    let x = fx.do Out "1"
    let y = fx.do Out "2"
    let z : Result Int [NotANumber]
    let z : Int|[NotANumber]
    let z = x + y
    z else 0

  let x : {Out} Result _ _
  let x = stdout.writeLine Out "asdf"

  with debug.stash
    debug.printf "{s:s}\n" {s=str}
    debug.printf "{i:s}{s:s}\n" {i=indent,s=str}

  with debug.stash
    > .printf "{s:s}\n" {s=str}
    > .printf "{i:s}{s:s}\n" {i=indent,s=str}

  with debug.stash
    | .printf "{s}\n" {str}
    | .printf "{s}{s}\n" {indent,str}

  with debug | .printf "{s}\n" {str}

  let re =
    """regex
    ^           # Matches start of line
    :blank:*    # Zero or more space-like chars
    (           # Capture the following sequence
      \w+       # At least one alphanumeric char
    )
    :blank:*    # Zero or more space-like chars
    $           # Matches end of line
    """

  let re =
    ```regex
    ^           # Matches start of line
    :blank:*    # Zero or more space-like chars
    (           # Capture the following sequence
      \w+       # At least one alphanumeric char
    )
    :blank:*    # Zero or more space-like chars
    $           # Matches end of line
    ```

  let re2 =
    with regex
    | ^           # Matches start of line
    | :blank:*    # Zero or more space-like chars
    | (           # Capture the following sequence
    |   \w+       # At least one alphanumeric char
    | )
    | :blank:*    # Zero or more space-like chars
    | $           # Matches end of line

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

decl f1 : Int, Int -> Int
defn f1 x y =
  int.+ x y

def f2 : Int, Int -> Int
let f2 x y =
  int.+ x y

fun f5 : Int, Int -> Int
fun f5 x y =
  int.+ x y

fn f6 : Int, Int -> Int
fn f6 x y =
  int.+ x y

let f8 : Int, Int -> Int
let f8 = { int.+ $1 $2 }

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

      # when run cap (opaque |> codec.decode json.codec) is
      #   | json ->
      #     { externalApi = Url json.externalApi
      #     , api = Url json.api
      #     , mode =
      #       when json.mode is
      #         | "production" -> Production
      #         | "test" -> Testing
      #         | _ -> Development
      #     }
      #   | _ ->
      #     { externalApi = Url "https://anapioficeandfire.com/api/characters/"
      #     , api = Url "https://our.own.api/"
      #     , mode = Production
      #     }

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
    [ :HttpGet "https://anapioficeandfire.org"
    , :HttpPost application.config.ourApi
    ]
  | Out is [ :StdOut ]


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

# Has algebraic side effects via http.get but is pure since it's only data
callAnApiOfIceAndFire : Int32 -> HttpRequest
let callAnApiOfIceAndFire =
  { http.get `https://anapioficeandfire.com/api/characters/${it}`
  }

# IO side effects via console.log
main : Sequence String -> ExitCode { NetRead, Stdout }
function main args =
  requestJonSnow : HttpRequest
  let requestJonSnow = callAnApiOfIceAndFire 583

  result : Result ExitCode [ StdoutError ]
  let result =
    task.attempt
      { run ->
        let raw = run Untrusted requestJonSnow
        let json = run Untrusted (raw |> codec.decode json.codec)
        when json is
          | Ok hero ->
              """
              # Inline assertions only run in specific environments, if there is a comment
              # attached to the expression it'll be shown on failure
              """
              expect hero.url == "https://anapioficeandfire.com/api/characters/583"
              expect hero.name == "Jon Snow"
              expect hero.culture == "Northmen"
              CliOk
          | Error NotFound ->
              let _ = run Trusted (stdout.println "Jon Snow not found")
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

  expect sequence.equals [2, 5, 10] nums

  let four = 2 |> { it*it }
  expect 4 == four

  let ret = when args is
    | [name, version] where "1.0.0" == version -> Ok
    | [name, ...rest] ->
      when name is
        | "dsl" -> Ok
        | _ -> Error
    | _ -> Error

  exitCode




type record X =
  { a : Nat
  , b : String
  , c : Decimal
  }


# Got TEA?

type Msg =
  | ClickSth

type Cmd msg =
  | DoSomething msg

let update : State, Msg -> Tuple (Cmd Msg) State
let update state msg =
  when msg is
    | ClickSth = tuple.new cmd.none { ...state }



module "core/very/experimental"


type class BooleanLogic? a b =
  with [ Hash a, Hash b, Truthy c ]

  equals : a, b -> c

  where
    operator (==) a b =
      equals a b


type Comparison =
  | LessThan
  | Equals
  | GreaterThan

class Sort? =
  compare : a, a -> Comparison
    where
      a implements Sort
  # operator <
  # operator >

class Append? =
  append a, a -> a
    where
      a implements Append
  # operator ++



# En-/Decoding, also important for interpolation and String format

bytes : List U8
bytes =
  """
  [ ( "Apples", 10 )
  , ( "Bananas", 12 )
  , ( "Orangs", 5 )
  ]
  """ |> Str.toUtf8

fruitBasket : List (Str, U32)
fruitBasket =
  [ ( "Apples", 10 )
  , ( "Bananas", 12 )
  , ( "Orangs", 5 )
  ]

class Encoding =
  toEncoder : val -> Encoder fmt
    where
      val implements Encoding
      fmt implements EncoderFormatting

class Encode =
  toBytes

class Decoding =
  decoder : Decoder val fmt
    where
      val implements Decoding
      fmt implements DecoderFormatting

class Decode =
  fromBytes ... -> Result

class Codec? =

expect Encode.toBytes fruitBasket json == bytes
expect Decode.fromBytes bytes json == Ok fruitBasket

class Hash? =
  hash : hasher, a -> hasher
    where
      a implements Hash
      hasher implements Hasher

class Inspect =
  toInspector : val -> Inspector f
    where
      val implements Inspect
      f implements InspectFormatter