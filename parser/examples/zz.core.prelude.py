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
  | OK with ( Truthy, Enum 200 )
  | Created with ( Truthy, Enum 201  )
  | NotFound with ( Enum 404 )
  | ServerError with ( Enum 500 )


module "core/lang"
  exposing
    | Result
    | Unit

type Result a err =
  | Ok a
  | Error err

# type Unit

