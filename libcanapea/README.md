# Canapea Compiler As A Library

The official "language intelligence" compiler-as-a-library of the Canapea Language. It bundles all the compiler facilities in one easy to use library with its main client being [our CLI](../cli/) which includes [a language-server-protocol implementation](../language-server/) for the time being.

This is a separate project from the [CLI](../cli/) because it is intended to be used by tooling that might be separate from our own language server implementation.

**TODO** Make `libcanapea` build ready so it can be consumed as a simple C library.

## Build

```sh
zig build

# Only generate support code
zig build generate-types
```


## Test

```sh
# Generate support code and run tests
zig build test
```
