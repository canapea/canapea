---
canapea: PackageConfig (Semantic 0 0 1)
---

# Example Application

```python

configuration
  exposing
    | package

import "canapea/config" as config
  exposing
    | Config
    | Credit(Author)
    | Dependency(Repository)
    | Include(Directory)
    | Package(Library)
    | Version(Semantic)

package : Config
let package =
  { package = Library "com.acme.myapp"
  , version = Semantic 0 0 1
  , include = [ Directory "src" ]
  , dependencies =
    { runtime =
      # You could pin the actual core library version
      [ Repository "org.canapea.core" (Semantic 0 0 1)
      ]
    }
  }

```