# Canapea Programming Language Design Documentation

This project documents the language design of the Canapea language.


## Canapea Language Design Pillars

The language is built on these core design pillars that govern all the specific architecture decisions.


### Secure By Construction

Canapea code and packages by themselves are pure, as in free of side-effects. Nobody installing a Canapea package should ever have to worry that their new dependency will track them, steal their data or "launch the nukes".

Code that wants to perform side-effects needs to declare them as pure data (a.k.a. [Algebraic Effects](https://en.wikipedia.org/wiki/Effect_system)). They must explicitly request capabilities from the user to actually perform those actions. Only the underlying platform a program is compiled against is actually able to change the "state of the world".

Capabilities can only be narrowed and never escalated.


### There Usually Should Be One Way To Do Things

Reading other people's code should make sense and not leave you wondering what language they've used. It should be easy to do the most secure and expressive thing so the user is lead into [the Pit of Success](https://blog.ploeh.dk/2023/03/27/more-functional-pits-of-success/).


### The Type System As Your Friendly Assistant

The compiler as the arbitrator of the type system should be helpful and inviting to help the user understand problems and fix them without suprises.


### Bring Your Own Domain Language

Canapea tries to avoid giving users well-known "footgun" features, even when they're used to them in other languages. This means that many "generic" container types don't come builtin with the language so the user is encouraged to use the language of their problem domain.

It should be easy and rewarding to use your domain's vocabulary so newcomers and non-programmers can look at code and make sense of it because it enables the use of the domain's [Ubiquitous Language](https://martinfowler.com/bliki/UbiquitousLanguage.html).


## Architecture Decision Records (ADR)

This directory contains the [Architecture Decision Records](https://github.com/joelparkerhenderson/architecture-decision-record) for the Canapea language design. Every markdown file corresponds to an architecture decision made at some point. The date is in the file name (year-month-day), sometimes there will be revisions to older decisions, those will be outlined in the documents themselves.


## Stream of Consciousness Architecture Discussion

This is just a chronological scratch list of ideas and how they've evolved over time before they'd actually do or don't make it to the status of an architecture decision for one reason or another.

### Evergreen

* [ ] capability security! Fine grained, NetRead("https://the.allowed.url/path/*")
* [ ] one way to do things is still the goal
* [ ] easy to read core library, no abbreviations
* [ ] ML-style type inference!
* [ ] autofmt without config!
* [ ] keep concurrency in mind for the core language design

<details open>
  <summary>Current Focus Topics</summary>

### 2025-07-13 Current Focus Topics

* [ ] Inline printf debugging living documentation?
* [ ] Development via tests like a jupyter notebook?
* [ ] Failable expressions like in [Verse](https://dev.epicgames.com/documentation/en-us/fortnite/verse-language-reference)?
  * This could support our goal to avoid booleans for other things as pure
    boolean logic
* [ ] Support modules as builders for "importing syntax" and custom DSLs?
* [ ] "driver" concept to provide capabilities and "platforms" as a
    collection of drivers while user code stays safely sandboxed
  * [x] no ffi interop in the language, only platform has access to ffi stuff!
  * [x] no sideeffects outside of platform!
  * [ ] roc-like sideeffect collection in error handling?
    * only a "crash" function, everything else is data?
* [ ] Generator templates a.k.a. gentlate?
  * Generator templates to keep boilerplate up-to-date is an interesting
    problem to look into. Every time a new `tree-sitter` version comes out
    it becomes more glaring that an automated solution would be very
    nice and we're nowhere near the LLVM versioning nightmare every language
    that made the decision to use it seems to be in
* [ ] documentation! not sure yet how to go about it exactly
  * [ ] Code documentation should be live documentation that's actually type
    checked and evolves with the code instead of getting stale
  * [ ] Language/Library documentation should be generated from source, there
    is no way to keep separate "codebases" in sync here
* [ ] string representation?
  * Still not sure how to go about strings in general, it feels like what
    Zig/Roc/Odin/... do to have Uint8 bytes part of the language and string
    handling in a library is a good idea because it's a complex topic you don't
    really want to tie to the language core
  * [ ] Interpolation is another one of those things that needs more thinking
      * On one hand you really want something like this handled by your
        language but with encodings like Unicode constantly evolving it's
        hard to make the argument to keep this locked up inside the language
        core. Maybe Mojo's approach to put everything it can into libraries
        is a good way to deal with this?
  * [ ] No string concat operator! Use library function or interpolation
      instead
* [ ] no boolean blindness (nobody does this but I like it)
  * We'll see whether or not we can get by without booleans for anything
    other than actual boolean logic
* [ ] first (big) program is the official language server
  * This still seems like a good idea, it's a non-trivial program that
    also dogfoods the whole compiler toolchain as well as the language
    itself
* [ ] specification of language like WASM SpecTech completely defined
    and automated?
  * Having an executable language spec would be very nifty indeed
  * Could work well with gentlates, if we're getting that working


#### Notes On Earlier Agenda Points

* [ ] No extra syntax for tuples, only 4-tuples allowed
  * elm tuples? max size tuples?
  * only records, no tuples?
  * right now it feels like making your own tuple type if you want them
    is the way to go
* [ ] Config is just language syntax DSLON
  * Not sure about this, sounded good on paper, maybe a common interchange
    format would be more suitable?
* [ ] Docker support?
  * Not sure where we stand on this, Zig should make Docker obsolete
    to a certain extent
* [ ] Do notation for callback hell?
  * It seems like we can get around this with gathering up errors from
    earlier code and have them be handled at the appropriate time, Zig does
    this very nicely, Odin has an interesting `or_return` operator for early
    returns on error which could be something to look into.
* [ ] Recursion? loops?
  * The idea to have all standard library collections actually be based
    on transducers sounds like a good trade-off. It's not clear how well
    that fits into the type system in the general case but having those
    building blocks be efficient and naturally as lazy or eager as you want
    without incurring massive overhead like allocating huge amounts of
    temporary data-structures by default seems like a huge win.
  * Recursion is interesting in that usually you'd just assume recursion is
    the way to go for an ML inspired language, not sure how to let people
    fall into the pit of success with this one, though. Is it really a good
    idea that someone new to the whole paradigm needs to know about tail-call
    optimization to not blow the stack of their very first programs?
    Roc has an interesting take on that at this point in time in that it
    allows for local mutation that's unobservable to the outside and also
    gives you a `for` loop you can early return from. This seems weird at
    first glance but on second thought it feels like a natural fit for Roc.
* [ ] support explicit `return` from function?
  * Seems as weird as having `for` loops but could have benefits for writing
    code that's easier to read
* [ ] pattern matching fragment naming?
  * There's not enough "real" Canapea code to judge whether or not this is
    useful right now.
* [ ] no `unit` type support
  * From a type system perspective there probably has to be a "bottom"
    element but maybe there is a way to keep that concept out of user space?
* [ ] scientific numbers? hex/binary/octal literals?
  * [x] This won't be part of the core language, unless you know what you're
      doing a number should behave as one could reasonably expect from math
      classes: `Int` is a BigInt, `Decimal` is an actual decimal with a
      precision that makes sense for real life usage. If you want or need
      `float` semantics, this should be part of a library.
  * [ ] There sure is a way to get all the obnoxious number literals and
      scientific notation into a program without the core having to deal
      with them until the end of time. Sounds like a good idea to put them
      into a driver/builder of some kind.
* [ ] good date support! but ~~maybe~~ just as library
  * At its core it's the same case as string handling, there is a moving
    target in changing time zones etc. that you don't want to have baked
    into the language as to not having to release constant maintainence
    updates to the core language just because of timezone data. Again
    sounds like a library/driver concern.
* [ ] no bulk imports ~~!~~
  * It's hard to tell right now how necessary a feature like this really
    is with barely any Canapea code in existence we can put this decision
    off for some time
* [ ] operators as function calls!
  * [x] no custom operators!
  * [x] People seem to like operators to some degree but most of the time
      it's probably better to give things a name because existing operators
      imply semantics that hardly any of those custom ones adhere to.
  * [x] There will be operators for builtin numbers
  * [ ] Not sure yet about how to allow operators for library provided number
      types like `float`. It seems silly to have those be special just
      because they may be provided as "official" implementations when other
      people could be writing much better libraries and won't have access
      to those operators that actually make sense.
* [ ] lazy/greedy?
  * While this is not Haskell it'd be nice to at least have to option to
    have lazy behavior for certain data structures. Transducers could be
    a good way to facilitate that.
* [ ] code as data? LISP is neat but not necessarily nice to look at
  * The dream is not dead yet, maybe the core language will be a LISP you
    can happily send over the wire? Who knows?
* [ ] macros?
  * [x] There will be no C-style macros, never
  * [ ] Zig's `comptime` concept seems like something we could adopt?
  * [ ] Maybe modules as builders could be use?
* [ ] language editions?
  * The goal is to keep "old" code working in some way, structural typing
    should help with being able to import old versions of libraries.
  * Maybe we can stabilize the core language AST to a degree that migrations
    are as seamless as possible?
  * Modules as builders could help with old code not getting stale so fast
    because new syntax would actually just be part of some driver you can
    import?
* [ ] traits/roc abilities?
  * Capabilities seem to be usable for a lot of stuff, right now it feels
    like we could get by without introducing more higher-level concepts
* [ ] nice VCS diffs!
  * The mandatory not configurable auto-formatter should help with that
    say goodbye to bike-shedding
* [ ] pre/post conditions, code contracts?
  * It would be neat to have actual semantic pre/post conditions and
    code contracts but it's unclear how useful that would actually be
    in "real" code at this point in time
* [ ] roc auto resolve serialization on usage
  * Yes! Inferring deserialization information from usage is so clever,
    a program is completely typed so why not use that information for
    codecs as well.
* [ ] memory model?
  * The plan is not to have a zero-cost abstraction language so having
    i.e. a reference counting memory model with some book-keeping for the
    core language doesn't seem like a bad idea right now.
  * Maybe we can steal an idea from somewhere to get to zero-cost
    abstractions anyway, that'd be great.
* [ ] Clojure-like dependencies on function level
  * [x] We want Clojure's dependencies on function level, not package level
  * [ ] packages with auto semantic versions? Does that make sense for
      function level dependencies?
  * Just import from anywhere, having more than one version of the same
    package should be a non-issue
  * Why nobody else stole this approach remains a big mystery
* [ ] roc, gleam, pipe operator ~~!~~
  * No auto-currying, weird at first but works more like people expect it to
  * Not sure about having the pipe operator in the first place, it's not
    very nice for discoverability because you kind of already have to know
    what you could pipe data into, maybe it's not so bad with a working
    language-server implementation but maybe this could be something that
    lands on the chopping block at some point?
* [ ] distributed like Unison lang?
* [ ] unison names of functions are "optional", type is the ID?
    solves `function == function?` and allows huge potential optimizations
* [ ] concurrency model(s)?
  * Even though concurrency is a ways off as a topic async should be first
    class consideration for the language design. As with security this is
    hard to put into an existing design at a later stage
  * No idea how to go about concurrency right now, gut-feeling is actors
  * [ ] actor model like erlang?
  * [ ] BEAM VM as backend/platform?
  * [ ] coroutine like GO?
  * [ ] threading?
  * [ ] green threads?
  * [ ] CRDT?
    * Concurrency and data reconciliation is a long ways off but, yes!
* [ ] roc side-effect with postfix "!"?
  * Not a big fan, there's certainly merit in looking at a function name
    and being able to tell that it does side-effects, needs more time in
    the oven.
* [ ] auto async?
  * This could be interesting should modules as builders be a thing. In
    Clojure you don't really have to think about code being async although
    there's still the need for suitable data-structures in that context.
* [ ] JS/WASM as backend?
  * Yes, having JS as a target should help getting a lot of real-world
    experience with the language while implementing the client side of the
    language server
  * [x] It's pretty certain that WASM will be a target in some form
* [ ] package platform with easy changes?
  * Having a central package registry doesn't seem like the best idea.
    The compiler could make sure that i.e. vendored code cannot do
    nefarious things by just processing Canapea source code.
  * There should be a way to keep dependencies safe to install while not
    restricting application authors on the sources from where to install
    their dependencies from, at least for user code.
  * For eventual drivers and platforms the situation is likely different
    but that's for future-designer to ponder



</details>

### 2025-04-11

Checked items are already part of the language design, the other points
have been migrated to a more recent discussion - they're only left here immutably for documentation purposes.

<details>

* [x] minimal syntax
* [x] expression based
* [x] kotlin lambda syntax
* [ ] no extra syntax for tuples, only 4-tuples allowed
  * elm tuples? max size tuples?
  * only records, no tuples?
* [ ] config is just language syntax DSLON
* [x] structural equality
  * definitely! This is also huge for de-/serialization and supporting multiple versions of the same dependency
* [ ] no string concat operator! Use library function or interpolation instead
* [ ] do notation for callback hell?
* [x] no auto-currying
  * auto-currying just seems to make the code harder to read and enable that
    annoying point-free style where every sense of a program that's actually
    doing something is lost
* [ ] recursion? loops?
* [x] pattern matching guards
* [ ] pattern matching fragment naming?
* [ ] no unit support!
* [ ] scientific numbers? hex/binary/octal literals?
* [x] println etc. via platform
  * The capability to write to `stdout` will be handled by something further
    down the line, right now the idea is to have "drivers" implement those
    and "platforms" are really just a collection of drivers that have
    access to a minimal API provided by the "platform"
* [ ] good date support! but maybe just as library
* [ ] one way to do things
* [ ] no bulk imports!
* [ ] operators as function calls!
* [ ] no custom operators!
* [x] last expression is return value
  * Works well for most cases
* [x] side effects as data with platform executing stuff!
* [ ] lazy/greedy?
* [ ] code as data? LISP is neat but not necessarily nice to look at
* [ ] macros?
* [ ] language editions?
* [x] capability security! Fine grained, NetRead("https://the.allowed.url/path/*")
* [ ] traits/roc abilities?
* [x] ML-style type inference!
* [ ] nice VCS diffs!
* [ ] string representation?
* [ ] CRDT?
* [ ] gentlate?
* [x] number formats! In64, Decimal as default everything else can be tedious
* [ ] documentation! not sure yet how
* [ ] pre/post conditions, code contracts?
* [ ] roc auto resolve serialization on usage
* [ ] roc platforms (kind of framework) with abilities with sandboxing
* [ ] memory model?
* [ ] green threads?
* [x] no ffi interop in the language, only platform has access to ffi stuff!
* [ ] no sideeffects outside of platform!
* [ ] roc sideeffect collection in error handling, only a "crash" function, everything else is data
* [ ] no boolean blindness (nobody does this but I like it)
* [x] roc Tests/assertions in code only run in debug/test but always up-to-date docs
* [ ] clj import from any place, dependencies on function level, not package level
* [x] easy to read core library, no abbreviations
* [ ] roc, gleam, pipe operator! no auto-currying, weird at first but works more like people expect it to
* [ ] first program is language server?
* [ ] specification of language like WASM SpecTech completely defined and automated?
* [ ] distributed like Unison lang?
* [ ] unison names of functions are "optional", type is the ID?
  -> function == function?
* [ ] coroutine like GO?
* [ ] roc async with postfix "!"?
* [ ] auto async?
* [ ] threading?
* [ ] actor model like erlang?
* [ ] BEAM VM as backend/platform?
* [ ] JS/WASM as backend?
* [ ] autofmt without config!
* [ ] package platform with easy changes
* [ ] packages with auto semantic versions? Does that make sense for the function level dependencies?


</details>
