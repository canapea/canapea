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

