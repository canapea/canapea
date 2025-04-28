#!/bin/sh

run() {
  set -e
  
  echo
  echo "# Outbox Asset Delivery"
  echo "This is your friendly outbox, distributing assets since 2025..."
  echo

  echo "## Deliveries"
  echo

  # The editor extension always wants a new copy of the most recent parser build
  cp parser/tree-sitter-canapea.wasm language-support-vscode/assets/
  echo "* [x] Language Support now got the current parser WASM"

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
}

(check_env || exit; run "$@");
