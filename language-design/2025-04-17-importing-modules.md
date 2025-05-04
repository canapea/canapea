# Importing Modules

No tracking issue available

Urgency: vital

## Revisions

* 2025-05-04: v1 - Initial version adapted from memory


## Problem Statement

One of the earliest design decisions of the language was that we would only allow type-level bindings like types and type constructors to be imported into a module's scope without qualification, everything else needed to be imported via the `as` syntax into a "module namespace".

```python
# Import design
import "some/datatype" as datatype # This `as` only understands low-level constructs like `let` and `function` bindings
  exposing
    # This `exposing` only understands type-level bindings
    | TypeA(Ctor1, Ctor2)
    # You can't import low-level bindings via `exposing`
    # | helperFunction # Syntax error!

# You can't access types via qualified syntax since they're not in low-level construct scope
# > datatype.TypeA # Syntax error!

# You could introduce local bindings to alias imported functions but just like in
# Go it is considered good style to always use imported functions qualified so it's
# easy to see where they come from. It also has the added benefit that you can make
# function names in modules short and concise, which is exactly what Go wants you
# to do
# > let newDatatype = datatype.new
# > newDatatype arg1 arg2
# vs
# > datatype.new arg1 arg2
```


## Considered Alternatives

A lot of consideration has gone into how to approach module imports, the chosen design seems to mitigate almost all of the (personally felt) shortcomings of what other languages like Haskell, Elm or even JavaScript and Python do.


## Prior Art

Most other ML-likes allow imports of everything into the module namespace unqualified but this always seemed wrong in the sense that it conflates type-level imports with value-level constructs.


## The Decision

Imports will be implemented as per originally stated in [problem statement](#problem-statement). Only types and type constructors may be exposed directly into the module scope, everything else needs to be named via the `as` syntax. Users will be encouraged to rely on using qualified access to imported module functions.

```python

import "some/datatype" as datatype
  exposing
    | TypeA(Ctor1, Ctor2)

```


### Who Decided?

* [mfeineis](https://github.com/mfeineis)


### Upsides

* Types in function signatures are conveniently in module scope and are easily visually distinguishable from using non-type-level things from other modules
* No name collisions of non-type-level imports and the user has to give module imports a name
* Short and concise function names in modules are encouraged since they won't collide with others
* Qualified access can be determined statically in syntax analysis without introducing more operators like `::` in Rust or C++ to distinguish module-level or type-level access
* This distinction in handling type-level things and low-level things emphasizes that those actually "live" in different scopes, something that is hard for newcomers to understand


### Downsides

* Allowing to `expose` Custom Type constructors into module scope arguably is a bit of a "cop-out": they're basically functions in how you use them, so technically we're disallowing specific kinds of functions - those that begin with an upper-case letter - to be accessed via the imported module namespace and allowing them to be brought into module scope via `exposing` but from a type system perspective they really belong to the type and just happen to work like functions for convenience. The `expose` syntax treats custom type constructors different enough from normal values that this trade-off seems OK at this point in time



## Post-Mortem

TBD
