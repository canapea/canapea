#!/bin/sh

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

  tree-sitter generate grammar.js \
    && tree-sitter test -r \
    && tree-sitter highlight --check --time --html --css-classes "$@" \
    >&2>&1 > "$TARGET"  

  # --check
  # --quiet
  # --html --css-classes
    
  echo "> " "$TARGET"
}

(./ci/00-ensure-test-env.sh || exit; run "$@");
