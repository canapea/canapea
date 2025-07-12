#!/bin/sh

run() {
  set -e
  
  echo "Bumping grammar version... PARAMS:" "$@"

  # Prefer tree-sitter that's installed via NPM so we know exactly
  # which version we're dealing with regarding ABI incompatibilities
  if ! command -v npm >/dev/null 2>&1
  then
    echo "NPM not found, using global tree-sitter instead"

    tree-sitter version "$@"
  else
    echo "NPM found, using 'npx tree-sitter'"

    npx tree-sitter version "$@"
  fi

  echo "OK"
}

(./ci/00-ensure-test-env.sh || exit; run "$@");
