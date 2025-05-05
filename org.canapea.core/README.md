---
# Tell Canapea tooling that this markdown file is actually a config file
canapea: PackageConfig (Semantic 0 0 1)
---

# The Canapea Core Library

Canapea package configs are akin to [Literate Haskell][], so it's documentation and configuration-as-code at once. All embedded Canapea code is considered part of the same file but you can actually break it up with Markdown. The code exposes a `package : Config`, everything is statically typed and even more importantly side-effect free while still having access to convience functions - even the script functions are just pure functions until the platform gives them the capabilites to change the state of the world. The compiler or your editor running the language-server helps getting your config right.

> If you need machine-readable package information the CLI can actually
> generate other interchange formats like JSON or YAML

This is the configuration header, at a glance we see that there is some code in here that wants to perform side-effects by just looking at the requested capabilities. We also see what the module is exposing, the package config and some functions.

```python

# TODO: Not sure about the actual syntax since `module` usually can't request capabilities, or can they?
configuration
  where
    [ capability "canapea/io" ( DiskRead, DiskWrite, EnvRead )
    , capability "canapea/lang" ( CodeWeave )
    ]
  exposing
    | package
    | generateBuiltins
    | extractInfoFromReadme

```

## Package

The package config is a record of type `Config`, you can use pure helper functions but you won't be able to perform side-effects outside of [scripts](#scripts).

```python

import "canapea/config" as config
  exposing
    # | Artifact(Readme)
    | Config
    | Credit(Author)
    | Dependency(Git, Local, Repository)
    | DependencyMapping(Alias)
    | LanguageEdition(Canapea2025)
    | Include(Directory, GlobPattern, Module)
    | License(BSD, MIT, Other, Proprietary, UPL1)
    | Meta(Website, Keyword)
    | Package(App, Library)
    | Provide(SealedNamespace, OpenNamespace)
    | Version(Latest, Semantic, UnsafeCommit, UnsafeTag)

# TODO: What do we do with "unsafe" variants like Git Tags? We don't know that they're actually valid...

import "canapea/lang/code/ast" as ast
import "canapea/lang/code/weave" as weave
import "canapea/io/env" as env
import "canapea/io/file" as file

package : Config
let package =
  { package = Library "org.canapea.core"
  , version = Semantic 0 0 1
  , provides =
    [ SealedNamespace "canapea"
    , OpenNamespace "experimental"
    ]
  , language = Canapea2025
  # TODO: , features = []
  , include =
    [ Directory "src"
    ]
  , exclude =
    [ Directory "src/__probably_not__"
    , GlobPattern "src/**/*.{h,hpp,c,cpp}"
    ]
  , credits =
    [ Author "Martin Feineis"
    ]
  , licenses =
    [ UPL1
    ]
  # , artifacts =
  #   [ Readme "README.md"
  #   ]
  , meta =
    [ Website "https://canapea.org"
    , Keyword "Canapea"
    , Keyword "Programming Language"
    , Keyword "Pure Functional Programming"
    , Keyword "Algebraic Effects"
    ]
  , dependencies =
    { runtime =
        [ Git "https://github.com/canapea/platform/cli" (Semantic 0 0 1)
        , Git "https://github.com/canapea/experimental/lib" (UnsafeTag "feature-x")
        , Local "../parser/examples/"
        , Repository "canapea/platform/cli" (Semantic 0 0 1)
        , Git "https://github.com/someone/custom" (UnsafeCommit "bnruna83498biq17b3498b92u34b59b29384b5bn")
        ]
    , development =
        [ Local "../cli"
        ]
    , test =
        [ Local "../cli"
        ]
    , overrides =
        [ Alias "tree-sitter" (Repository "tree-sitter" (Semantic 0 24 4))
        , Alias "tree-sitter-v0-25-3" (Repository "tree-sitter" (Semantic 0 25 3))
        , Alias "tree-sitter-latest" (Repository "tree-sitter" Latest)
        ]
    }
  }

```

## Scripts

Scripts are functions that may perform side-effects so we need to declare the capabilities we need. These are just meant for building the package before it is pushed to a repository.

The end-user is in no danger of ever running any side-effects from an installed package, all Canapea code is just pure functions and data - unlike other package systems there are no hidden install hooks that can execute arbitrary side-effects. If you want code to change the state of world, like writing a file, or even sending a message to `stdout` you need to request the capability to do so. The CLI will check-in with the user to delegate those capabilities.

```python

# Capabilities are attached to Custom Type Constructors that
# then act as tokens to hand to the underlying platform
# performing the side-effects
type Capability =
  | Trusted is
    [ DiskRead "./src"
    , DiskWrite "./src"
    , EnvRead [ "CI" ]
    , CodeWeave
    , StdOut
    ]
  | PackageFileGen is
    [ DiskRead "./README.md"
    , DiskWrite "./generated.pkg.json"
    , StdOut
    ]

```

```python

# TODO: Not sure how to do scripts right now, this is a WiP sketch

generateBuiltins : _ -> _ { CodeWeave, DiskRead, DiskWrite, EnvRead } [ ALotOfErrorsProbably, ... ]
function generateBuiltins _ =
  task.attempt
    { runSideEffect ->
        # Trusted side-effects via requested capabilities
        let run = { customTask -> runSideEffect Trusted customTask }

        let intBuiltinFileName = "./src/lang/number/int/builtin.cnp"

        let _ci = run (env.readVar "CI")
        let intBuiltin = run (file.read "./src/lang/number/int/builtin.cnp")
        let intImpl = run (file.read "./src/lang/number/int/builtin.c")

        # Pure function, no side-effects here
        let intInterface = ast.generateWeaveInterface intBuitin

        let intWasmWeave = intImpl |> weave.asWasm intInterface
        let intWeave = run (weave.apply intBuiltinFileName wasmWeave)
        run (file.write "intBuiltinFileName")
    }

```


```python

# The Canapea package config is rather esoteric, easy for humans to read
# but a nightmare for any tooling to handle so there are built-in tools
# to generate all kinds of data interchange formats
generateJsonFile : _ -> _ [ FileReadFailed, FileWriteFailed ] { DiskRead, DiskWrite }
function generateJsonFile _ =
  # Generating a JSON file from the package config is so common
  # that there's a built-in convenience function for it
  task.attempt
    { run ->
        run PackageFileGen (config.generateJson "./generated.pkg.json")

        ## Roughly translates to...
        # let readme = run PackageFileGen (file.read "./README.md")
        # let json = config.toJson readme
        # run PackageFileGen (file.write json "./generated.pkg.json")
    }

```

[Literate Haskell]: https://wiki.haskell.org/index.php?title=Literate_programming
