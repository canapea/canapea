"""
# Complex Development Module Example

TODO: This is just a syntax dump of everything the parser knows about right now.

"""

module "experimental/examples/complex"

import "core/platform/cli"
  exposing
    | ExitCode
      ( Ok as CliOk
      , Error as CliError
      )
import "core/io/stdout" as stdout
import "core/date" as date
  exposing
    | Instant
import "core/net"
  exposing
    | Url(Url)
import "core/net/http" as http
  exposing
    | HttpRequest
    | HttpStatus(HttpOk)
import "core/codec"
  exposing
    | Codec
    | Opaque
import "core/codec/json" as json
import "core/web/console" as console
import "core/web/html" as html
import "core/math" as math

# Importing the same module in different versions is totally fine
import "core/http@legacy"
  exposing
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

configure : Capability, Opaque -> Result AppConfig [ Incapable ]
function configure capability opaque =
  # "capability" is just the basic capability to run this init code and
  # nothing more. So you can't just launch rockets while initializing an app
  task.attempt
    { run ->
      when run cap (opaque |> codec.decode json.codec) is
        | json ->
          { externalApi = Url json.externalApi
          , api = Url json.api
          , mode =
            when json.mode is
              | "production" -> Production
              | "test" -> Testing
              | _ -> Development
          }
        | _ ->
          { externalApi = Url "https://anapioficeandfire.com/api/characters/"
          , api = Url "https://our.own.api/"
          , mode = Production
          }
    }

# Capabilities can be attached to Custom Type constructors and then
# be used when performing side-effects. The resulting subsystem that
# abstracts the platform is then literally incapable of escalating
# what is declared.
type Untrusted =
  | Untrusted is [ NetRead app.externalApi ]

type Trusted =
  | Trusted is [ StdIn, StdOut, NetRead app.api, NetWrite app.api ]



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
addOne : Int -> Int
function addOne x =
  # int.add 1 x
  # use Int +
  x + 1

append : String -> String
function append txt =
  # string.append txt postfix
  # use String ++
  # (++) txt "-postfix"
  txt ++ "-postfix"


addTwo : Decimal -> Decimal
let addTwo = { it + 2.0 }

vectorLength : Point3d -> Decimal
let vectorLength =
  { { x, y, z } ->
    math.squareRoot (x*x + y*y + z*z)
  }


function withTypeHoleForDevelopment _ =
  # You can't release this because the compiler knows about your TODO
  debug.todo "This function hasn't been implemented yet"

printSomething: _ -> Result _ [ StdoutError ] { Stdout }
function printSomething _ =
  task.attempt
    { it (stdout.println "Evil side-effect in lambda???") }

let returnTheQuestion = { "What do you know?" }

record SomeDataFragment =
  { hello : String
  , world : String
  , today : Instant
  }

let someData =
  { hello = "Hello"
  , world = "World"
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

let someDataCopy =
  { ...someData
  , world = "OMG"
  }

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


# Got TEA?

type Msg =
  | ClickSth

type Cmd msg =
  | DoSomething msg

update : State, Msg -> Tuple (Cmd Msg) State
function update state msg =
  when msg is
    | ClickSth = tuple.new cmd.none { ...state }



"""
#
# type concept experiments
#
"""

type Truthiness =
  | IsTruthy
  | IsFalsy

"""
# "Attachable" to specific Custom Type constructors to make them act
# like Boolean.True in other languages. Helps to avoid the common
# Boolean-Blindness anti-pattern.

```canapea
type TestResult =
  | Pass Int is [ Truthy ]
  | Partial Int is [ Truthy, Comparable ]
  | Fail Int

let threshold = 20
let pass = Pass 42
let partial = Partial 23
let fail = Fail 10
expect pass && (partial >= threshold) && (not fail)
```
"""
type constructor concept Truthy k =
  isTruthy : k -> Truthiness

  exposing
    function isFalsy x =
      when isTruthy x is
        | IsTruthy -> IsFalsy
        | _ -> IsTruthy


type constructor concept Falsy k =
  isFalsy : k -> Truthiness

  exposing
    function isTruthy x =
      when isFalsy x is
        | IsFalsy -> IsTruthy
        | _ -> IsFalsy


"""
# Can be implemented for types so you get (not), (==) and (/=) for free.
"""
type concept Eq a =
  equals : a, a -> Truthy

  exposing
    function not x =
      when x is
        | Truthy -> Falsy
        | _ -> Truthy
    operator (==) x y =
      equals x y
    operator (/=) x y =
      not (equals x y)


type concept instance Eq Int =
  function equals x y =
    int.equals x y


type concept instance Eq Decimal =
  function equals x y =
    decimal.equals x y


type concept Natural a =
  add : a, a -> a
  subtract : a, a -> a
  multiply : a, a -> a
  one : a
  zero : a

  exposing
    operator (+) : a, a -> a
    operator (+) x y =
      add x y

    operator (-) : a, a -> a
    operator (-) x y =
      subtract x y

    operator (*) : a, a -> a
    operator (*) x y =
      multiply x y


type concept instance Natural Int =
  function add x y =
    int.add x y

  function subtract x y =
    int.subtract x y

  function multiply x y =
    int.multiply x y

  let one = 1
  let zero = 0


type concept Modulo a =
  with [ Natural a ]

  modulo : a, a -> { value : a, remainder : a }

  exposing
    operator (%) : a, a -> { value : a, remainder : a }
    operator (%) x y =
      modulo x y


type concept instance Modulo Int =
  function modulo x =
    int64.modulo x


type concept Fractal a =
  with [ Natural a ]

  divideBy : a, a -> Result a [ DivideByZero ]

  exposing
    operator (/) : a, a -> Result a [ DivideByZero ]
    operator (/) x y =
      divideBy x y


type concept instance Fractal Decimal =
  function divideBy x y =
    decimal.divideBy x y





# module "core/very/experimental"

# type class BooleanLogic? a b =
#   with [ Hash a, Hash b, Truthy c ]
#
#   equals : a, b -> c
#
#   where
#     operator (==) a b =
#       equals a b
#
#
# type Comparison =
#   | LessThan
#   | Equals
#   | GreaterThan
#
# class Sort? =
#   compare : a, a -> Comparison
#     where
#       a implements Sort
#   # operator <
#   # operator >
#
# class Append? =
#   append a, a -> a
#     where
#       a implements Append
#   # operator ++

#
# En-/Decoding, also important for interpolation and String format
#

# bytes : List U8
# bytes =
#   """
#   [ ( "Apples", 10 )
#   , ( "Bananas", 12 )
#   , ( "Orangs", 5 )
#   ]
#   """ |> Str.toUtf8
#
# fruitBasket : List (Str, U32)
# fruitBasket =
#   [ ( "Apples", 10 )
#   , ( "Bananas", 12 )
#   , ( "Orangs", 5 )
#   ]
#
# class Encoding =
#   toEncoder : val -> Encoder fmt
#     where
#       val implements Encoding
#       fmt implements EncoderFormatting
#
# class Encode =
#   toBytes
#
# class Decoding =
#   decoder : Decoder val fmt
#     where
#       val implements Decoding
#       fmt implements DecoderFormatting
#
# class Decode =
#   fromBytes ... -> Result
#
# class Codec? =
#
# expect Encode.toBytes fruitBasket json == bytes
# expect Decode.fromBytes bytes json == Ok fruitBasket
#
# class Hash? =
#   hash : hasher, a -> hasher
#     where
#       a implements Hash
#       hasher implements Hasher
#
# class Inspect =
#   toInspector : val -> Inspector f
#     where
#       val implements Inspect
#       f implements InspectFormatter
#
#
#
# module
#
# import "core/number"
#   exposing
#     | Number
