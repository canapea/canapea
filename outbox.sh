#!/bin/sh

run() {
  set -e
  
  echo
  echo "# Outbox Asset Delivery"
  echo "This is your friendly outbox, distributing assets since 2025..."
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
