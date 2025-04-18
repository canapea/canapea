# Canapea Parser

This is the home of the language parser.

## Testing

```sh
# Run tests
ci/test.sh

# Run tests with "ONLY" in the name
ci/test.sh -i ONLY 

# Run tests and update AST snapshots
ci/test.sh -u

# Parse example file and output AST
ci/parse-example.sh examples/basic.cnp
```
