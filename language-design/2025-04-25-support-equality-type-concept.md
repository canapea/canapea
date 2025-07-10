# Support Equality Type Concept

[Tracking Issue](https://github.com/canapea/canapea/issues/21)

Urgency: vital


## Revisions

* 2025-05-25: Accepted ADR v1
* 2025-05-04: v1 - Initial version adapted from VCS issue


## Problem Statement

Canapea is a statically typed function programming language. As such the "time to first question about monads" will probably be close to zero. For language implementation and conveniences like binary operators for number types as well as comparibility and equality for language constructs having higher-kinded types seems like a good idea: it's working well in pretty much every other ML dialect there is. The goal is to have actual language syntax and eventually associated type-level facilities inside the type-checker so we can provide the user with the most convenient language experience possible while keeping maintenance burden to a minimum.

```python

# Example for `Eq` type concept based on type constructor concept `Truthy`,
# if you wonder what `Truthy` is supposed to mean: the tracking issue has
# a detailed explanation on this

type constructor concept Truthy k =
  capability : k -> Truthy

# Attaching a type constructor concept to an actual type constructor
type Rating =
  | Positive is [ Truthy ]
  | Neutral
  | Negative

type concept Eq a =
  # The "interface" the type needs to implement
  equals : a, a -> Truthy

  # The features a type gets for implementing the "interface"
  exposing
    operator (==) : a, a -> Truthy
    operator (/=) : a, a -> Truthy

# Implementing Eq via type concept instance
type concept instance Eq Int =
  function equals x y =
    int.equals x y

```

Please note that the decision to [make high-level features available as an actual language feature](https://github.com/canapea/canapea/issues/20) is out-of-scope here, please refer to the associated tracking issue and/or architecture decision.

### Nomenclature Reasoning

For why this is not called a `class` in Canapea, as it is in Haskell see [Prior Art](#prior-art). The initial nomenclature was `type trait` but traits also have different meanings in different languages, the traits in PHP are almost nothing like the traits in Rust. While rubber-duckying about this with someone unfamiliar with programming languages the word `concept` came to mind very often, so the language feature `type trait`, explained to the non-initiated was constantly explained in terms of a `concept` of things so why not use `type concept` and be done with trying to explain a word that essentially means what another word already means? This is where it's worth to borrow something from C++ where it's appropriate, even for a statically typed functional language.

As this is not planned as an actual published stable language feature the syntax is deliberately designed as clunky conditional syntax behind the `type` keyword so we don't pollute the reserved words of the language with common names the user probably wants to use.


## Considered Alternatives

* We could leave unstable/unpublished features like these higher-kinded types out of the language completely but first "implementation" sketches of core and application code made it clear that not having conveniences like binary operators, equality, comparison etc. for builtin language constructs is really annoying and off-putting. Even the big inspiration for Canapea, the [Elm language](https://elm-lang.org) has builtin builtin support for equality, comparison and the like and they're implemented as type classes under the hood inside the compiler
* We could use templating like C++ does with its `concept` but that doesn't seem like a good fit for a functional programming language of the ML family when higher-kinded types are so much more proven to be working. Maybe this could be a good strategy for code generation to do the actual monomorphization of types but for the design of a language this feels very off-putting
* Most other ML-style languages have some form of higher-kinded types because it fits well into the type system, we haven't come across a language of this style that uses a dramatically different approach to polymorphism


## Prior Art

In Haskell our `type concept` lives out their live as the ever-confusing `class` syntax, sure it's conveniently short but many people have preconceptions what a `class` is from other languages and even in those languages classes rarely live up to [the original "object orientation" concept as defined by Alan Kay](https://wiki.c2.com/?AlanKaysDefinitionOfObjectOriented). So it doesn't seem like a good idea to attach anything to a keyword named `class` these days in general.


## The Decision

We will implement Type Concepts and associated features for now as syntax inside the parser and re-visit later when it comes to actual type-checking, when we will be better equipped to judge whether or not the complexity actually outweighs the benefits it gives for language implementation.

We will [re-visit this decision on occasion](https://github.com/canapea/canapea/issues/59) so we don't leave dead features in the language.


### Who Decided?

* [mfeineis](https://github.com/mfeineis)

### Upsides

* Proven language features in many ML-like languages
* Right now, while there's no running Canapea code, it's also easier to reason about "virtually" than other approaches since it's so close to already proven features in other languages
* If it turns out that we don't want/need it we can throw it out prior to language release and we won't break anything but our own pride


### Downsides

* It makes the parser a bit more complex but not by much
* It will make the type-checker a lot more complex which is why we want to re-consider before laying hand on the actual implementation


## Post-Mortem

TBD
