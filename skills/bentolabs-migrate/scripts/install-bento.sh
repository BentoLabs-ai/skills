#!/usr/bin/env bash
# Step 2: Install bentolabs-sdk alongside the existing SDK.
#
# Picks the package manager (uv / poetry / pdm / pip). Set
# ADK_PRESENT=1 to also install the [adk] extra. Adds a placeholder for
# BENTOLABS_API_KEY to .env.
#
# Do NOT uninstall raindrop-ai or langfuse here. The source SDK stays
# installed until Step 5 verification passes.

set -euo pipefail

ADK_PRESENT=${ADK_PRESENT:-0}

if command -v uv >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  if [ "$ADK_PRESENT" = "1" ]; then uv add "bentolabs-sdk[adk]"; else uv add bentolabs-sdk; fi
elif command -v poetry >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  if [ "$ADK_PRESENT" = "1" ]; then poetry add "bentolabs-sdk[adk]"; else poetry add bentolabs-sdk; fi
elif command -v pdm >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  if [ "$ADK_PRESENT" = "1" ]; then pdm add "bentolabs-sdk[adk]"; else pdm add bentolabs-sdk; fi
else
  if [ "$ADK_PRESENT" = "1" ]; then pip install "bentolabs-sdk[adk]"; else pip install bentolabs-sdk; fi
fi

if [ -f .env ]; then
  if ! grep -q "^BENTOLABS_API_KEY=" .env; then
    echo 'BENTOLABS_API_KEY=bl_pk_...' >> .env
  fi
else
  echo 'BENTOLABS_API_KEY=bl_pk_...' > .env
fi

echo "Set BENTOLABS_API_KEY in .env to your real key from https://platform.bentolabs.ai"
echo "Keep raindrop-ai or langfuse installed until Step 5 verification passes."
