#!/bin/sh

set -e

if ! command -v node >/dev/null 2>&1
then
  echo "Required dependency node is missing"
  exit 1
else
  echo "Required dependency node has been found, proceeding..."
fi
