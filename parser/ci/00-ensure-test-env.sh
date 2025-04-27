#!/bin/sh

set -e

if ! command -v tree-sitter >/dev/null 2>&1
then
  echo "Dependency tree-sitter is missing"

  if ! command -v npm >/dev/null 2>&1
  then
    echo "Secondary dependency npm is missing"
    exit 1
  else
    echo "Secondary dependency npm has been found, proceeding..."
  fi
else
  echo "Dependency tree-sitter has been found, proceeding..."
fi
