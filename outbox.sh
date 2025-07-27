#!/bin/sh

run() {
  set -e

  WORKDIR=$(pwd)

  echo
  echo "# Outbox Asset Delivery"
  echo
  echo "This is your friendly outbox, distributing assets since 2025..."
  echo
  echo

  echo "## Deliveries"
  echo

  echo "### Language Support"
  echo

  cp parser/tree-sitter-canapea.wasm language-support-vscode/assets/
  echo "* [x] Language Support now got the current parser WASM"

  cp parser/canapea.tmLanguage.json language-support-vscode/syntaxes/
  echo "* [x] Language Support now got the current TextMate grammar"

  echo
  echo "### libcanapea"
  echo

  cd libcanapea/ \
    && zig build generate-types \
    && echo "* [x] libcanapea generated support code is now up to date"
  cd "$WORKDIR"

  echo
  echo "## Verification and Smoketests"
  echo

  # CLI
  cd "$WORKDIR" \
    && zig build test && printf ".." \
    || printf ".x"
  cd "$WORKDIR"

  echo

  echo
  echo "Outbox done."
}

check_env() {
  set -e

  if ! command -v cp >/dev/null 2>&1
  then
    echo "Required dependency cp not found."
    exit 1
  else
    echo "Required dependency cp found, proceeding..."
  fi

  # TODO: Do a proper version comparison for Zig?
  if ! command -v zig >/dev/null 2>&1
  then
    echo "Required dependency zig not found."
    exit 1
  else
    echo "Required dependency zig found, checking version..."
    ZIG_VERSION=$(zig version)
    if [ "$ZIG_VERSION" = "0.14.1" ]
    then
      echo "  zig version == 0.14.1 supported, proceeding..."
    else
      echo "  zig version ==" "$ZIG_VERSION" "unsupported."
      exit 1
    fi
  fi

}

(check_env || exit; run "$@");
