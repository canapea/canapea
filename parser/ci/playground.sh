#!/bin/sh

ABI_VERSION="15"

run() {
  set -e

  echo "Building parser for WASM and starting playground PARAMS:" "$@"

  # Prefer tree-sitter that's installed via NPM so we know exactly
  # which version we're dealing with regarding ABI incompatibilities
  if ! command -v npm >/dev/null 2>&1
  then
    echo "NPM not found, using global tree-sitter instead"

    tree-sitter generate --abi "$ABI_VERSION" --build \
      && tree-sitter build \
      && tree-sitter playground "$@"
  else
    echo "NPM found, using 'npx tree-sitter'"

    npx tree-sitter generate --abi "$ABI_VERSION" --build \
      && npx tree-sitter build \
      && npx tree-sitter playground "$@"
  fi

  echo "OK"
}

(./ci/00-ensure-test-env.sh || exit; run "$@");
