#!/bin/sh

run() {
  set -e
  
  echo "Building parser for WASM and starting playground PARAMS:" "$@"
  tree-sitter generate grammar.js \
    && tree-sitter build \
    && tree-sitter playground "$@"
  
  # --quiet
  # --grammar-path

  echo "OK"
}

(./ci/00-ensure-test-env.sh || exit; run "$@");
