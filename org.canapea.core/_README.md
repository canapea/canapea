---
package: org.canapea.core
type: library
version: 0.0.1
license:
  SPDX: UPL-1.0
author: Martin Feineis
# exposing:
#   - core
exclude:
  - undecided
canapea:
  edition: 2025
keywords:
  - Canapea
  - Programming Language
  - Pure Functional Programming
  - Algebraic Effects
  - Strict Evaluation
  - Static Type System
# dependencies:
#   - source: https://github.com/canapea/platform/cli
#     version: 0.0.1
#     versionName: pre
#     checksum: sha512-as8fq93nr9we8fp9erbf34htpq34t34tubtq3iu4tb
---

# org.canapea.core

The core library of the Canapea language.

TODO: How do we actually organize/name the packages?


## Documentation

TODO: It's neat to have the README and its linked documentation as a more readable and self-documenting "package.json", YAML frontmatter should suffice for the necessary structural data. The drawback is that both Markdown and YAML are rather large, full of edge-cases and the format is hard to parse for other tooling.

## Scripts

TODO: Wouldn't it be neat to have scripts listed here and then be able to just run them from the README like an NPM script?

<details>
  <summary>Scripts</summary>

### Install

```sh

module "canapea"

import "canapea/net/url" as url
  exposing
    | Protocol(Https)
import "canapea/config/semver" as semver

let version = semver.version 0 0 1
let atVersion = semver.toAtVersion version

let schema =
  url.new
    { protocol = Https
    , host = "canapea.org"
    , path = [ "core", "config", "canon", atVersion ]
    }


{ schema = schema
, package = module.name
, version = version
}
```

### Test

TODO: No considerations yet on testing the actual library core other than wanting AST diffs via `canapea ast generate-tests` tooling.

```sh
# Works, but the tests are useless right now, the parser versions
# seem to be out of sync somehow and there are other a lot of
# errors on top of the AST not being anywhere close to stable
canapea ast generate-tests "org.canapea.core/**/*.cnp" --flatten --target "parser/test/corpus/"
```

</details>

