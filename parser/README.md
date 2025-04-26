# Canapea Parser

This is the home of the language parser.

## Testing

```sh
# Run tests
ci/test.sh

# Run tests with "PCT0077" tag in the name
ci/test.sh -i PCT0077

# Run tests and update AST snapshots
ci/test.sh -u

# Parse example file and output AST
ci/parse-example.sh examples/basic.cnp

# Highlight file and output as HTML in local/examples/complex.cnp.html
ci/highlight.sh examples/complex.cnp 

# Start tree-sitter playground
ci/playground.sh
```
