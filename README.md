# Canapea

Welcome to the home of the Canapea Programming Language

```python
# Obligatory "Hello, World" app

app with
  { platform = "core/platform/cli"
  , main = "main"
  }

import "core/platform/cli"
  | ExitCode(Ok, Error)
import "core/platform/cli/stdout" as stdout


main : Sequence String -> ExitCode { Stdout }
function main _ =
  task.attempt
    { run ->
        when run (stdout.println "Hello, World!") is
          | Ok -> Ok
          | else -> Error
    }


```

<details>
  <summary>Sub-Project High-Level Summary</summary>

### [Parser](./parser/)

The language parser is generated with the help of tree-sitter. For technical details consult its [README](./parser/README.md).


</details>
