#!/bin/sh
# Install local git hooks directory for this repository
set -e

echo "Setting git core.hooksPath to .githooks"
git config core.hooksPath .githooks

echo "Done. To verify: git config core.hooksPath"