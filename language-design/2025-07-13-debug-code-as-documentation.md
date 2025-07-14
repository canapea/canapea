# Debug Code As Documentation

[Tracking Issue](https://github.com/canapea/canapea/issues/45)

Urgency: nice-to-have (but quick-win)


## Revisions

* 2025-07-13: Accepted ADR v1
* 2025-07-13: v1 - Initial version


## Problem Statement

`expect` is already nice to capture some intent but it'd be nice, if you could just leave your "printf" console log output, acting as living documentation of the code since it'd break in case something changes but it'll be stripped out in a release build.

The code can be in "passive" or "active" mode, so using i.e. `debug.stash` puts it into "passive" mode - it's still checked and participates in everything normal code does, it just doesn't run.

```python
# livedoc is code that documents usage or
# retains useful printf debugging that can
# be toggled active or passive

let fn _ =
  # Runs on a debug build
  debug
    expect answer == 42

  debug.stash
    # This may contain usage examples, code that's
    # relevant for a future stage of a feature, anything
    # you want the compiler to check and the editor
    # to refactor so it's up-to-date but it won't run
    # until "unstashed"
    expect pi == 3.14159
```


## Considered Alternatives

* [x] Keep on having this type of code in comments where it will rot until inevitably an IDE looks for those things while refactoring anyways
* [x] The usual recommendation is to delete code like this and bring it back via version control, this obviously removes the ability to document or remind you of stuff


## Prior Art

There is no prior art of a feature like this as far as I can tell, people seem to either despise `printf` debugging or they strip this code out after it served its initial purpose.


## The Decision

This is a quick-win and seems very useful to me. The ADR will be marked to revisit at a later stage to see how well this works in reality.

We will [re-visit this decision on occasion](https://github.com/canapea/canapea/issues/59) so we don't leave dead features in the language.

### Who Decided?

* [mfeineis](https://github.com/mfeineis)

### Upsides

* This is particularily useful for learning new APIs and keeping the original sample from the documentation around for some time. It's also nice for future ideas you don't want to forget. But the main purpose is that you can put some effort in your "printf" debugging output, keep it around and it won't rot - it demonstrates how something is use, maybe what you expect or maybe it's something completely different you want to know about at that point.
* This feature is a nice-to-have for me personally because I tend to program against the types of an API for quite a while and usually the hassle to involve a debugger isn't necessary. I also don't want to rely too much external tooling.
* Reading the code in a normal text editor gives me the whole story.


### Downsides

* This can lead to keeping around useless stuff that still needs to maintained but you could also ignore the feature altogether


## Post-Mortem

TBD
