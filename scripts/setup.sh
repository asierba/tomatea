#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

git config core.hooksPath .githooks
