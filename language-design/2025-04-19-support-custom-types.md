# Support Custom Types

[Tracking Issue](https://github.com/canapea/canapea/issues/5)

Urgency: vital

## Revisions

* 2025-04-19: Accepted ADR v1(VCS)
* 2025-05-04: v1 - Initial version adapted from VCS issue


## Problem Statement

Union types for modelling data are a well understood concept in static functional languages like Haskell, OCaml, Rust, Elm, etc. this is the basic building block of the whole language.


## Considered Alternatives

Not having union types is not really an option since they're the basic building block of the whole language design.


## Prior Art

They work very well in Elm and other statically typed functional languages.


## The Decision

The language is built on user defined union types, we will follow Elm's nomenclature in calling them "Custom Types". We will go even further in not providing built-in Custom Types like `Boolean`, `Maybe/Option` etc. to encourage using domain language everywhere.

### Who Decided?

* [mfeineis](https://github.com/mfeineis)

### Upsides

* The user can model their domain with readable Custom Types with the actual domain language
* It avoids the [Boolean Blindness code-smell](https://existentialtype.wordpress.com/2011/03/15/boolean-blindness/) by construction
* Calling them Custom Types seems to be easier for newcomers to understand. It also disincentivises assumptions over how they "should" work based on other languages. This is a nice property for us since we're planning on doing some esoteric things with them that other languages don't support.


### Downsides

* Custom Types are usually "nominal" types which may introduce problems with equality for data-interchange but since the language is in control of side-effects there's no reason to just make things work structurally like with records under the hood


## Post-Mortem

TBD
