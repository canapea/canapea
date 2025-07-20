application

import capability "canapea/io"
  exposing
    | +StdErr
    | +StdOut

import "canapea/experiments/host"
  exposing
    | Host
import "canapea/format" as fmt
import "canapea/io/stderr" as stderr
import "canapea/io/stdout" as stdout

import "experimental/cli" as cli
  exposing
    | CliArgs(Args)
    | ExitCode

application config
  { { host } ->
    let usage =
      """
      Sample CLI App

      Usage: sample-cli-app [options] <who>

      arguments:
        who         Who to greet

      options:
        --help      Display this help screen
      """
    { main =
        when host is
          | Browser -> cli.mainWithJsonFlags usage main
          | Native -> cli.mainWithConsoleArgs usage main
          | else -> error.UnsupportedHost host
    }
  }


type Cap =
  | Out is [ +StdOut, +StdErr ]


type CliReturnValue =
  | Success is [ ExitCode 0 ]
  | Usage is [ ExitCode 1 ]
  | Fail is [ ExitCode 2 ]


let main : _ -> <+StdOut,+StdErr>Eventual CliReturnValue []
let main args =
  when args is
    | Args { help } usage ->
      let _ = help
      let _ = stderr.writeLine Out usage
      Usage
    | MissingArgs _ usage ->
      let _ = stderr.writeLine Out usage
      Usage
    | InvalidArgs usage ->
      let _ = stderr.writeLine Out usage
      Fail
    | Args { who } _ ->
      let _ = stdout.writeLine Out (fmt.format "Hello, {subj:s}!" {subj=who})
      Success


###


module "experimental/cli"
  exposing
    | CliArgs(..)
    | ExitCode
    | mainWithConsoleArgs
    | mainWithJsonFlags

import "canapea/codec" as codec
  exposing
    | DecodeError
    | Decoder
    | OpaqueValue


type CliArgs data usage =
  | Args data usage


let mainWithJsonFlags : usage -> (Args data usage -> Eventual _ _) -> (OpaqueValue -> Eventual _ [InvalidArgs, MissingArgs])
let mainWithJsonFlags usage main =
  { opaque ->
    let decoded : Eventual _ [DecodeError]
    let decoded = codec.decode JsonArgsCodec opaque

    let parsed : Eventual (Args data usage) [DecodeError,MissingArgs]
    let parsed = parseArgs decoded usage

    when parsed is
      | DecodeError err -> error.InvalidArs err
      | else args -> main args
  }


let mainWithConsoleArgs : usage -> (Args data usage -> Eventual _ _) -> (OpaqueValue -> Eventual _ [InvalidArgs, MissingArgs])
let mainWithConsoleArgs usage main =
  { opaque ->
    let decoded : Eventual _ [DecodeError]
    let decoded = codec.decode ArgsCodec opaque

    let parsed : Eventual (Args data usage) [DecodeError,MissingArgs]
    let parsed = parseArgs decoded usage

    when parsed is
      | DecodeError err -> error.InvalidArs err
      | else args -> main args
  }


let parseArgs : decoded, Sequence Uint8 -> Eventual (Args _ usage) [MissingArgs]
let parseArgs decoded usage =
  debug.todo _


type constructor concept ExitCode Uint4 =
  debug.todo _


type concept ArgsCodec (Args data usage) =
  debug.todo _

type concept instance Decoder (ArgsCodec (Args data usage)) =
  let decode : OpaqueValue -> (Args data usage)
  let decode opaque =
    debug.todo _


type concept JsonArgsCodec (Args data usage) =
  debug.todo _

type concept instance Decoder (JsonCodec (Args data usage)) =
  let decode : OpaqueValue -> (Args data usage)
  let decode opaque =
    debug.todo _


# type concept instance Encoder (ArgsCodec a) =
#   let encode : a -> OpaqueValue
#   let encode args =
#     debug.todo _
