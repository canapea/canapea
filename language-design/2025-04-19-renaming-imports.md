# Renaming Imports

[Tracking Issue](https://github.com/canapea/canapea/issues/9)

Urgency: vital

## Revisions

* 2025-04-19: Accepted ADR v1(VCS)
* 2025-05-04: v1 - Initial version adapted from VCS issue


## Problem Statement

Name collisions when importing modules is a real problem, even in [our little core library sketch](https://github.com/canapea/canapea/issues/55) Custom Types and their constructors just happen to have similar or equal names. It's better to make a decision now so we can actually write our own code in an idiomatic way - and if it turns out there's a better way to address this we can fail fast and make those decisions before releasing the language and having to break people's code later.


## Considered Alternatives

* We could leave it as is and ignore the need - users will probably be annoyed and find "clever" ways around this, we're not OK with this
* We could leave it as is and introduce qualified access to types as the user already has the ability to give the "module namespace" a custom name but this would go against a fundamental design decision of the language to distinguish values from type-level constructs, so no, we won't do that.
* We could remove the `exposing` syntax entirely so everything a module exports would have to be accessed qualified, which again would go against a fundamental design decision of the language. It'd also be tedious for function signatures and although we're planning on using a Hindley-Millner type inference strategy - a.k.a. "all types of the whole programm can be inferred without annotations" - we want to encourage writing annotations as this is usually a big part of the living documentation of a program in statically typed functional languages. People will again find ways around this and be very annoyed, so we won't do that.
* We could allow exposing everything into module scope, not just type-level things which would again go against a fundamtental design decision of the language.


## Prior Art

Elm has decided not to support this kind of renaming at all, which leads to workarounds like having to introduce intermediate modules that just import and re-export under a different name which just seems silly and prone to errors. Other languages like JavaScript make it easy to give names to imports and this works out really well in practice. As with everything the user needs to practice moderation with those features as this can get confusing very quickly.


## The Decision

In light of real-world needs, it seems reasonable to support renaming types and type constructors so that's what we will do. The syntax is fairly straight-forward, we just re-use the `as` keyword to introduce new name bindings. Most of this can even be checked in syntax-only inside the parser without any advanced semantic knowledge: the `exposing` syntax only supports type names anyways. The only thing that needs to be checked at a later stage is that you haven't given the same name to more than one binding.

```python
import "app/lib"
  exposing
    | T as M ( U as K, V as L )
```

We will [re-visit this decision on occasion](https://github.com/canapea/canapea/issues/59) so we don't leave dead features in the language.


### Who Decided?

* [mfeineis](https://github.com/mfeineis)

### Upsides

* Easy imports that work conceptually the same across all modules so the user doesn't have to circumvent a missing language feature
* Keeps the fundamental separation of type-level concepts and values in that you need different syntax to import them

### Downsides

* The renaming syntax potentially makes the import clauses more verbose which is unfortunate but seems worth the trade-off at this point in time


## Post-Mortem

TBD
