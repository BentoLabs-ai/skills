#!/usr/bin/env bash
# Install bentolabs-cli.
#
# Requires Python 3.10 or higher.
# Recommended: install with uv into an isolated tool environment.

set -euo pipefail

if command -v uv >/dev/null 2>&1; then
  uv tool install bentolabs-cli
else
  python3 -m pip install --user bentolabs-cli
fi

bentolabs version
