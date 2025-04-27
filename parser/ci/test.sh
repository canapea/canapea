#!/bin/sh

ABI_VERSION="14"

run() {
  set -e
  
  echo "Generating and testing parser... PARAMS:" "$@"

  # Prefer tree-sitter that's installed via NPM so we know exactly
  # which version we're dealing with regarding ABI incompatibilities
  if ! command -v npm >/dev/null 2>&1
  then
    echo "NPM not found, using global tree-sitter instead"

    tree-sitter generate --abi "$ABI_VERSION" --build grammar.js \
      && tree-sitter test --rebuild "$@"
  else
    echo "NPM found, using 'npx tree-sitter'"

    npx tree-sitter generate --abi "$ABI_VERSION" --build grammar.js \
      && npx tree-sitter test --rebuild "$@"
  fi

  echo "OK"
}

(./ci/00-ensure-test-env.sh || exit; run "$@");
