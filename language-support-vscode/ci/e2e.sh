#!/bin/sh

# export CODE_TESTS_PATH="$(pwd)/client/out/test"
# export CODE_TESTS_WORKSPACE="$(pwd)/client/testFixture"

run() {
  set -e
  
  echo "Running tests for extension... PARAMS:" "$@"

  # node "$(pwd)/client/node_modules/vscode/bin/test"

  node --test "${PWD}/test/*.test.js"
}

(./ci/00-ensure-test-env.sh || exit; cd .; run "$@");
