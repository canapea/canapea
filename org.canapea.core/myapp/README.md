---
org.canapea.lib/package: v0.0.0
---

# Example Application

```python

module "com.acme.myapp"

import "org.canapea.lib/package" as pkg

module config
  { package = pkg.library "com.acme.myapp"
  , version = v0.0.1
  , include = [ pkg.directory "src" ]
  , builtin =
    # FIXME: Can you can pin the actual core library version?
    [ "canapea" |> pkg.repository "org.canapea.core" v0.0.0
    , "canapea/lib" |> pkg.repository "org.canapea.lib" v0.0.0
    ]
  }

```
