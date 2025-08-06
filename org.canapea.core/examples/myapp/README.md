---
org.canapea.core/config: v|0.0.0
---

# Example Application

```python

package "com.acme.myapp"

import "canapea::config" as cfg
  exposing
    | License(Dual)
    | Spdx(MIT,BSD3)

package config
  { version = v|0.0.0
  , license = Dual MIT BSD3
  , include = [ cfg.directory "./src/" ]
  , builtin =
    [ "canapea" |> cfg.coreRepository v|0.0.0
    # Weird people want "I'm a Teapot" gone...
    , "canapea::io/net/http" |> cfg.coreRepository v|0.0.0
    # The builtin float type might be sub-par, so it's not part of core
    , "canapea::lang/float" |> cfg.coreRepository v|0.0.0
    # Timezone data is maleable, so that deserves a separate package
    , "canapea::lang/date/timezone" |> cfg.coreRepository v|0.0.0
    ]
  , dependencies =
    [ "myorg" |> cfg.directory "./deps/myorg/"
    , "another" |> cfg.gitRepository "https://github.com/anotherorg/std.git" "tag"
    , "oldcanapea" |> cfg.repository "org.canapea.core" v|0.0.0
    ]
  }

```
