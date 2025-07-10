# Rewrite from Rust to Zig

[Tracking Issue](https://github.com/canapea/canapea/issues/73)

Urgency: vital


## Revisions

* 2025-06-29: v1 - Initial version


## Problem Statement

Rust doesn't feel good to work in. The language server `rust-analyzer` is slow even with this small of a codebase and that's not likely to change as the compiler itself is infamous for being slow. The level of abstraction is too high, it's constantly a hunt for what Trait implementation provides what, you can't easily tell what code does even though it's all written by one person right now. The error messages of basic Rust are very good but this goes out of the window with essentially all real-world code using any kind of library (including Rust std) because of the incessant macro usage that mangles the whole output.

Having written some Zig it's really a better fit for a compiler, you can go as low-level as you want, cross-compilation out of the box, C interop is trivial, the build system is amazing. On top of that the standard library is not a jumble of macros and high-level unreadable soup like the Rust codebase seems to be in general. It's also fun to write Zig, way more fun than Haskell or Rust. You feel instantly productive, testing is part of the language, no friction at all. The code might not be good code but it was fun to write, the tooling is fast, it's exciting to learn something new - the polar opposite to the Rust story so far. The Error handling approach is really interesting. We might even consider stealing some good ideas for Canapea.


## Considered Alternatives

* [x] Stay with Rust: not really happy with how the code feels and the tooling is not in a good spot
* [x] C2x: The language is still full of undefined behavior and the best build tooling is using Zig as your C compiler... so why not use the better language, if it's already there?
* [x] C++: Nope, nope, nope, nope... nope
* [x] Odin: cool ideas, too Windows centric, no cross compilation, plenty of language ideas to adopt with Canapea
* [x] Jai: it's basically like Odin, still in closed beta, the creator doesn't seem trustworthy at all as a person
* [x] Mojo: not a good fit, an MLIR backend could be interesting for us. Has a noteworthy approach of putting as much of the functionality into libraries so even basic types live outside the language and compiler and can be iterated on independently. The creator implies they have solved the borrow checking problem way better than Rust.
* [-] Haskell/OCaml: not interested in getting deeper with those after doing a Zig PoC
* [x] Roc: really interesting features, way too early to use and not a good fit for compilers by their own admission, we can adopt a lot of ideas for Canapea
* [x] Go: the syntax is ugly, generics look horrendous, it's also garbage collected, if we're switching to lower-level language it should be a real low-level language

Zig: 0.14.1 is still under heavy development but the language itself, its project goals and governance look like they are a perfect fit. The documentation could be better but the language and standard library code is easily readable in most cases.


## Prior Art

[Roc's reasoning to rewrite in Zig](https://gist.github.com/rtfeldman/77fb430ee57b42f5f2ca973a3992532f) sounds like it's got a lot in common with the situation with Canapea, we're way more early to think about a switch to something different so this rewrite was rather easy.


## The Decision

We will implement Type Concepts and associated features for now as syntax inside the parser and re-visit later when it comes to actual type-checking, when we will be better equipped to judge whether or not the complexity actually outweighs the benefits it gives for language implementation.

It's unlikely we'll change this decision in the future, Zig seems like a really good fit, unless its creator Andrew loses the plot and totally switches his language with every minor version up to v1.0.

We already have a complete proof-of-concept of all the features we've already implemented in Rust prepared as a [Strangler Application](https://www.thoughtworks.com/en-de/insights/articles/embracing-strangler-fig-pattern-legacy-modernization-part-one) living side-by-side with the existing code. We only need to remove the Rust artifacts and do some module reshuffling while we're at it. Exciting times.


### Who Decided?

* [mfeineis](https://github.com/mfeineis)

### Upsides

* Code is more straightforward
* Zig is fun to learn and write
* Zig language and standard library code is easy to read and understand
* We can drop down to as close to the metal as we want
* Explicit memory management helps with reasoning about it and may influence how Canapea approaches the problem
* Build toolchain is great, cross-compilation, seamless C interop in both ways
* Zig leaps ahead in feature set with every release
* Zig is developed by a non-profit entity that can sustain itself even at this stage of development
* Zig tooling is fast, not feature complete but it's enough to get productive instantly
* Comptime enables a lot of zero cost abstractions

### Downsides

* Zig is an unproven language in comparison
* Zig tooling isn't feature complete yet
* You could argue Zig has "not invented here" syndrome on steroids, Zig is a C compiler, does its own code generation for x86 and aarm64 at this stage to get rid of LLVM at some point
* Rust is more mature and has the concept of editions


## Post-Mortem

TBD
