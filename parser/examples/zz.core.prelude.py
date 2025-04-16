module "core/prelude"
# TODO: roc platforms? custom target platform implementations?

# # TODO: Should we supply Maybe, etc.?
# #       Roc doesn't have it, just Result and roll-your-own
# type Maybe a
#   | Just a as Truthy
#   | Nothing as Falsy

# # TODO: type alias?
# type alias Args as Sequence String

# TODO: Inline modules for normal code?
# TODO: OCaml param modules?
module "greet"
  | hello

function hello who
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
  #| Unit
  | Result(..)
  | Truthy | Falsy # | Enum | Flag?
  # TODO: import syntax constructs sounds cool
  | (=) | (|>) | (:)
  | as | crash | expect | function | let | record | type | when

import "core/lang/boolean" as boolean

# Task needs implementation in platform
import "core/task" as task
  | Task

import "core/sequence" as sequence
  | Sequence | ([])

import "core/tuple" as tuple
  | Tuple
  | Tuple3
  | Tuple4

import "core/string" as string
  | String

import "core/math" as math

import "core/number"
  | Number | (+) | (-) | (*) | modulo | divide

import "core/number/decimal"
  | Decimal

import "core/number/int"
  | Int64

import "core/number/float"
  | Float64

import "core/date"
  | Instant

#import "core/test/expect" as expect

# Http IO needs implementation in platform
import "core/http"


module "core/http"
  | HttpStatus

type HttpStatus
  | OK as Truthy, Enum(200)
  | Created as Truthy, Enum(201)
  | NotFound as Enum(404)
  | ServerError as Enum(500)


module "core/lang"
  | Result
  | Unit

type Result a err
  | Ok a
  | Error err

type Unit

