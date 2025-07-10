# Inline Testing Via Expect Syntax

[Tracking Issue](https://github.com/canapea/canapea/issues/17)

Urgency: low

> The *need* for this is not very high right now since there isn't even any real code to test but from a language design perspective it's very appealing to have testing as a first-class citizen and make it as frictionless as possible.


## Revisions

* 2025-04-21: Accepted ADR v1(VCS)
* 2025-05-04: v1 - Initial version adapted from VCS issue


## Problem Statement

Usually languages leave testing things to an external library. There isn't an agreed upon "best way"(tm) to approach testing but leaving testing out of the language design seems to lead to fracturing of the commmunity a language into non-compatible ways to test things.

[Roc](https://roc-lang.org) goes a different way here in having special `expect` syntax built into the language itself to make inline assertions about code essentially everywhere in your code, it even allows you to execute code branches that don't compile at a point in time so all tests that can be run will be run.

Having this kind of assertion at the language level allows to have builds that run tests, leave out those tests

```python
function subtractOne x =
  expect x > 0
```


## Considered Alternatives

* Just leave this out or for later consideration. This however would prevent a big opportunity to dog-food this kind of feature for [our own core library](https://github.com/canapea/canapea/issues/55) and see whether or not this would actually be useful or just cruft. Should it turn out that this is a bad fit for the language we can remove the feature prior to release and won't have to break any clients
* Implement it but as a module that you import or is imported by default in `prelude` could be a way to have easy access to testing but we'd be missing out on the [potential synergy effects](#potential-synergy-effects) having this implemented as actual language syntax so it seems like the better option to have it as an actual language feature. We can still rip the feature out prior to release as stated above.


## Prior Art

* Right now this kind of test integration into static languages seems to only exist in [Roc](https://roc-lang.org) so this is a cutting-edge feature.
* From personal experience "living documentation" that is actually checked by the compiler or at runtime so the user has to maintain or get rid of it is way more likely to be maintained properly than doc comments.
* It also seems to be a common re-occurance to leave in `console.log` statements as documentation on how to use things or how things work but since they're only comments they'd get out of sync very quickly.
* The seemingly now defunct `packer` library by [Dean Edwards](http://dean.edwards.name/packer/) (with a ["don't use this" node port](https://github.com/evanw/packer)) had a very popular feature to remove everything after leading `;;;` so you could leave in log statements for debugging but have them removed in a release build


## The Decision

In light of the potential synergy effects and just because it seems like a good idea to have testing as part of the language so it's as frictionless as possible this feature will be implemented as actual language syntax.

We will [re-visit this decision on occasion](https://github.com/canapea/canapea/issues/59) so we don't leave dead features in the language.


### Who Decided?

* [mfeineis](https://github.com/mfeineis)

### Upsides

* Without having a lot of "practice" in writing Canapea code it's hard to tell the actual need for integrated, language-level testing but it seems very appealing to have testing as frictionless as possible as part of the language core

#### Potential Synergy Effects

There seems to be potential for synergy effects for [tests as debugging and documentation at the same time](https://github.com/canapea/canapea/issues/45) and [verifying `type concept` via contracts](https://github.com/canapea/canapea/issues/28)


### Downsides

* It's more language syntax and probably more work to integrate the feature in a useful way, right now the upsides seem to outweigh this effort


## Post-Mortem

TBD
