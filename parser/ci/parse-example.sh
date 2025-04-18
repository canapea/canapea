#!/bin/sh

run() {
  set -e
  
  echo "Generating and testing parser... PARAMS:" "$@"
  tree-sitter generate grammar.js && tree-sitter parse "$@"
  echo "OK"
}

(./ci/00-ensure-test-env.sh || exit; run "$@");
