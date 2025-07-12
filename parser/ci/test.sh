#!/bin/sh

ABI_VERSION="15"

run() {
  set -e
  
  echo "Generating and testing parser... PARAMS:" "$@"

  # Prefer tree-sitter that's installed via NPM so we know exactly
  # which version we're dealing with regarding ABI incompatibilities
  if ! command -v npm >/dev/null 2>&1
  then
    echo "NPM not found, using global tree-sitter instead"

    tree-sitter generate --abi "$ABI_VERSION" --build \
      && tree-sitter test "$@"
  else
    echo "NPM found, using 'npx tree-sitter'"

    npx tree-sitter generate --abi "$ABI_VERSION" --build \
      && npx tree-sitter test "$@"
  fi

  echo "OK"
}

(./ci/00-ensure-test-env.sh || exit; run "$@");

# ci/test.sh --overview-only --stat all --rebuild
# ci/test.sh --include PTC0002
