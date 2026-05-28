#!/usr/bin/env bash
#
# WHAT THIS DOES
#   Installs the Bento command-line tool (bentolabs-cli) and then prints
#   its version to confirm the install worked.
#
# REQUIREMENTS
#   Python 3.10 or newer.
#
# HOW IT INSTALLS
#   If you have uv, we install the CLI as an isolated tool (the cleanest
#   way — it won't clash with your project's packages). If you don't have
#   uv, we fall back to a normal pip install for your user account.

# Stop immediately if any command fails, so problems are obvious.
set -euo pipefail

if command -v uv >/dev/null 2>&1; then
  uv tool install bentolabs-cli
else
  python3 -m pip install --user bentolabs-cli
fi

# Print the version. If this prints a number, the install worked.
bentolabs version
