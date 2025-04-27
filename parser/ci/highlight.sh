#!/bin/sh

ABI_VERSION="14"

run() {
  set -e
  
  echo "Generating parser and highlight PARAMS:" "$@"

  echo "  PARAM FILE:" "$1"
  FILE="$1"

  if [ -z "$1" ]
  then
    echo "All parameters are required."
    exit 1
  fi

  TARGET="local/$FILE.html"

  # Prefer tree-sitter that's installed via NPM so we know exactly
  # which version we're dealing with regarding ABI incompatibilities
  if ! command -v npm >/dev/null 2>&1
  then
    echo "NPM not found, using global tree-sitter instead"

    tree-sitter generate --abi "$ABI_VERSION" --build grammar.js \
      && tree-sitter test --rebuild \
      && tree-sitter highlight --check --time --html --css-classes "$@" \
      >&2>&1 > "$TARGET"  
  else
    echo "NPM found, using 'npx tree-sitter'"

    npx tree-sitter generate --abi "$ABI_VERSION" --build grammar.js \
      && npx tree-sitter test --rebuild \
      && npx tree-sitter highlight --check --time --html --css-classes "$@" \
      >&2>&1 > "$TARGET"  
  fi
    
  echo "> " "$TARGET"
}

(./ci/00-ensure-test-env.sh || exit; run "$@");
