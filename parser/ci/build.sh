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

    tree-sitter generate --build --abi "$ABI_VERSION" \
      && tree-sitter test \
      && tree-sitter build "$@" \
      && tree-sitter build --wasm "$@" \
      && tree-sitter parse --time --no-ranges --stat --quiet examples/**/*.cnp
  else
    echo "NPM found, using 'npx tree-sitter'"

    npx tree-sitter generate --build --abi "$ABI_VERSION" \
      && npx tree-sitter test \
      && npx tree-sitter build "$@" \
      && npx tree-sitter build --wasm "$@" \
      && npx tree-sitter parse --time --no-ranges --stat --quiet examples/**/*.cnp
  fi

  echo "OK"
}

( ./ci/00-ensure-test-env.sh || exit; run "$@" \
; if [ -z "$CI_TOKEN" ]; then (cd .. || exit; ./outbox.sh) fi
);
