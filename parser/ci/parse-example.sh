#!/bin/sh

# ci/parse-example.sh --stat --time --encoding=utf8 --no-ranges 

ABI_VERSION=15

run() {
  set -e
  
  echo "Generating and testing parser... PARAMS:" "$@"
  # tree-sitter generate grammar.js && tree-sitter parse "$@"

  if ! command -v npm >/dev/null 2>&1
  then
    echo "NPM not found, using global tree-sitter instead"

    tree-sitter generate --abi "$ABI_VERSION" --build \
      && tree-sitter parse "$@"
  else
    echo "NPM found, using 'npx tree-sitter'"

    npx tree-sitter generate --abi "$ABI_VERSION" --build \
      && npx tree-sitter parse "$@"
  fi

  echo "OK"
}

(./ci/00-ensure-test-env.sh || exit; run "$@");
