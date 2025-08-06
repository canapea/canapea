# Canapea Parser

This is the home of the language parser.

## Testing

```sh
# Run tests
ci/test.sh

# Run tests with "PTC0077" tag in the name
ci/test.sh --include PTC0077

# Run tests and update AST snapshots
ci/test.sh --update

# Run tests, display overview and all stats
ci/test.sh --overview-only --stat all

# Parse example file and output AST
ci/parse-example.sh examples/basic.cnp

# Highlight file and output as HTML in local/examples/complex.cnp.html
ci/highlight.sh examples/complex.cnp

# Start tree-sitter playground
ci/playground.sh
```

## Versioning

```sh
# Bump grammar version
ci/version.sh x.y.z
```
