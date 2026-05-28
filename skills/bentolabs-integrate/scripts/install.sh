#!/usr/bin/env bash
# Step 2: Install bentolabs-sdk and set BENTOLABS_API_KEY.
#
# Use the package manager that matches the project (pip / uv / poetry /
# pdm). If Step 1d found Google ADK, install the [adk] extra so
# bento.instrument() can activate the integration.
#
# Keys come from https://platform.bentolabs.ai. The prefix is bl_pk_;
# the SDK validates it up front and raises
# BentoAuthError("invalid_api_key_format") on a bad key.

set -euo pipefail

ADK_PRESENT=${ADK_PRESENT:-0}   # set ADK_PRESENT=1 to install the extra

if command -v uv >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  if [ "$ADK_PRESENT" = "1" ]; then
    uv add "bentolabs-sdk[adk]"
  else
    uv add bentolabs-sdk
  fi
elif command -v poetry >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  if [ "$ADK_PRESENT" = "1" ]; then
    poetry add "bentolabs-sdk[adk]"
  else
    poetry add bentolabs-sdk
  fi
elif command -v pdm >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  if [ "$ADK_PRESENT" = "1" ]; then
    pdm add "bentolabs-sdk[adk]"
  else
    pdm add bentolabs-sdk
  fi
else
  if [ "$ADK_PRESENT" = "1" ]; then
    pip install "bentolabs-sdk[adk]"
  else
    pip install bentolabs-sdk
  fi
fi

# Add the key placeholder to .env (the real secret lives in the user's
# secret manager). Skip if already present.
if [ -f .env ]; then
  if ! grep -q "^BENTOLABS_API_KEY=" .env; then
    echo 'BENTOLABS_API_KEY=bl_pk_...' >> .env
  fi
else
  echo 'BENTOLABS_API_KEY=bl_pk_...' > .env
fi

echo "Set BENTOLABS_API_KEY in .env to your real key from https://platform.bentolabs.ai"
