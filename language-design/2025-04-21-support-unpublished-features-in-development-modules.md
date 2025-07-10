# Support Unpublished Features In Development Modules

[Tracking Issue "core" modules](https://github.com/canapea/canapea/issues/20)

[Tracking Issue "experimental" modules](https://github.com/canapea/canapea/issues/27)

Urgency: vital


## Revisions

* 2025-05-21: Accepted ADR v1
* 2025-05-04: v1 - Initial version adapted from VCS issue


## Problem Statement

Like Elm we want to be able to use high-level features to implement the language itself and its core modules while keeping the actual language feature set itself lean and close to the goal of "there's usually one way to do things". The easiest way to do this seems not to introduce language feature switches or anything like that, ideally these won't ever be necessary, but just giving code in certain namespaces access to more capabilities, which neatly lines up with one of the fundamental language goals to [delegate capabilities](https://github.com/canapea/canapea/issues/26).

The basic implementation will just look at the namespace of the current module and only provide access to unstable unpublished features, if it's on the internal allow-list. For experimentation we will introduce another "experimental" namespace where all the footguns of the unpublished language implementation can be used but they will be restricted for usage in actual libraries or applications.

```python
module "core/lang"

# Works since "core" is on the allow-list for "footguns" and experiments
# but module can only be written and published by the core development team
type concept Eq a =
  # ...
```

```python
module "experimental/lib"

# Works since "experimental" is on the allow-list for "footguns" and experiments
# but module can only published by the core development team
type concept Eq a =
  # ...
```

```python
module "some/app"

# Syntax error, the language doesn't support this feature
type concept Eq a =
  # ...
```

## Considered Alternatives

* We could make high-level type features part of the official language but not only would we have to maintain the API forever, regardless of its actual usefulness in the field, but it would also go against "there's usually one way to do things". This is unless the whole language pivoted to higher-level type approaches like Monads/Arrows/Applicatives etc. - if the language was to go the Elm-way of trying to keep things as simple as possible would fracture users into "let's do it as intended" and "I have my monads, why use anything different". So this goes against the fundamental design principals of the language.
* We could remove the high-level features in favor of using exactly what everyone else uses for language implementation but that seems rather silly right now. It's easy to see that conveniences like common math operators like `(+)` just working with builtin numbers make sense. Always having to use `int.add` et al seems pointlessly tedious for a programming language. We might revisit this in the future but as it stands, implementing some concept of equality, comparibility and general numbers makes sense for builtin features. Letting i.e. everyone define their own Narsil operators `([-|=====~~>)` on the other hand is a completely different matter, which not so coincidentally is [tracked elsewhere](https://github.com/canapea/canapea/issues/32). The same goes with monads that don't obey the monad laws and cause all kinds of weird behavior etc. - maybe this can be mitigated by [actually checking higher level concept laws](https://github.com/canapea/canapea/issues/28). We can still take these features out before language release in case they're overkill in the first place without breaking anyone else's code.


## Prior Art

It seems that the only family of languages that restrict its published feature set are "Elm-likes". Every other language lets you use all the features they have to offer. So naturally this is a very unpopular decision for a language design to make. People quickly feel patronized if not outright insulted by "not letting them use" the full feature set the language implementation uses under the hood. This is especially true with statically typed functional languages where the first question always seems to be whether or not there will be support for type classes.

Let's take [Scala](https://www.scala-lang.org) as an example: it supports basically every programming paradigm there is, so naturally there's a whole slice of the community that only writes monadic code which in turn is incomprehensible to other slices that pool around the class-oriented features, ad inifitum. This fracturing of a language community is outlined very well in [Roc-lang's documentation](https://www.roc-lang.org/faq.html#arbitrary-rank-types).


## The Decision

The best course of action for the language itself right now seems to be to follow in Evan Czaplicki's footsteps and do it the Elm-way of having a small "user-facing" language while features can be implemented in a controlled maner under the hood with higher kinded types as an implementation detail that might change when we know more at a later stage in life. It seems like a good idea for experimentation to provide a way for users to fiddle with unstable/unpublished features via a special "experimental" namespace that can't be used in published code.

We will [re-visit this decision on occasion](https://github.com/canapea/canapea/issues/59) so we don't leave dead features in the language.


### Who Decided?

* [mfeineis](https://github.com/mfeineis)

### Upsides

* From personal experience with Elm, it turns out that having a smaller published language where there's usually one way to do things has beneficial effects on readability, maintainability, the ability learn the language as a newcomer and maintainence of the language itself.
* It's easier to add features later than take away features that are already part of a language, we're going to start out with a smaller set and we'll see what happens from there


### Downsides

* From personal experience with Elm people will be peaved by this. The communication needs to address this up-front: either you can live with the feature set the language has or it's not a good fit right now, the goal of the language is not growth but to be a reasonably well designed language that's useful. There's no RFC process planned right now, the hope is that the language at v1.0.0 will address some needs and if it turns out people actually use it and the need arises there's still the possibility to introduce RFCs or whatever process later.


## Post-Mortem

TBD
