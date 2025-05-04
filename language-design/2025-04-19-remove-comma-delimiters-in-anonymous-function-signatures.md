# Remove Comma Delimiters In Anonymous Function Signatures

[Tracking Issue](https://github.com/canapea/canapea/issues/8)

Urgency: moderate but quick-win for consistency

## Revisions

* 2025-05-04: v1 - Initial version adapted from VCS issue


## Problem Statement

The original syntax for anonymous functions was adapted from Kotlin and included the comma delimiters between function arguments. The reason for going with this syntax including the curly braces was to have them stand out visually. They look like blocks in other languages like C, Java, JavaScript, Kotlin etc. and we're going to use them for performing side-effects using `task.attempt` so having them be clearly visible as "blocks that do side-effects" is a nice benefit. In most other functional languages it's often required to put lambdas into parens when handing them around due to associativity anyways or use funky operators to mess with the associativity like `(<|)` in Elm. So surrounding them in curlies by default gives the added benefit of visual consistency and not having to deal with the operator cruft.

Having comma separators is arguably easier for the parser to parse but it is inconsistent with how function arguments of function declarations work. Seems like a quick-win for consistency to just don't have them.

```python
# Old syntax
let selectSecond =
  { fst, snd, trd -> snd }

# New syntax without , delimiters
let selectSecond =
  { fst snd trd -> snd }
```


## Considered Alternatives

We could just leave it like it is but we're so early in language design that it seems silly to not go for quick-wins and consistency.


## Prior Art

It's really a matter of taste and consistency and we like consistency here.


## The Decision

Comma delimiters will be removed, the current parser implementation seems to be astoundingly OK with this. Having record patterns in function arguments could've made problems but it seems we've built the grammar just well enough that it can handle the missing delimiters.

### Who Decided?

* [mfeineis](https://github.com/mfeineis)

### Upsides

* Consistency
* Less visual noise


### Downsides

* Can't think of any downsides really, the only anticipated issue turned out to be a non-issue since it doesn't make the parser more complex, it's just fine with the change


## Post-Mortem

TBD
