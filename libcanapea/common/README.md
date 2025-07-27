# Canapea Compiler As A Library Common

Collection of common types for the [official "language intelligence" compiler-as-a-library](../libcanapea/) of the Canapea Language.

This lives in a separate project because the rest of the toolchain should not rely on implementation details of the actual parser library being used.

Generators for support code can be found in [codegen/](./codgen/).

## Build

```sh
# Pure build without support generating code
zig build

# Generate support code
zig build generate-types
```


## Test

```sh
# Run unit tests
zig build test
```
