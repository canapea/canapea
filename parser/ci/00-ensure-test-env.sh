#!/bin/sh

set -e

if ! command -v tree-sitter >/dev/null 2>&1
then
  echo "Required CI dependency tree-sitter is missing"
  exit 1
else
  echo "Required CI dependency tree-sitter has been found, proceeding..."
fi
