#!/bin/sh

run() {
  set -e
  
  echo "Generating and testing parser... PARAMS:" "$@"
  tree-sitter generate && tree-sitter test -r "$@"
  echo "OK"
}

(./ci/00-ensure-test-env.sh || exit; run "$@");
