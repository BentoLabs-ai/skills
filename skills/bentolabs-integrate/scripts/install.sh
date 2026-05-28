#!/usr/bin/env bash
#
# WHAT THIS DOES
#   Step 2 of the integration. It installs the Bento Python SDK and puts
#   a placeholder for your API key in the .env file.
#
# WHEN TO RUN IT
#   Only for the two SDK paths: the Google ADK auto-instrument path, or
#   the manual track_ai path. The direct-export path installs nothing,
#   so skip this script entirely if that's your path (see SKILL.md Step 3).
#
# BEFORE YOU RUN IT
#   If Step 1 found Google ADK, set ADK_PRESENT=1 first. That tells the
#   script to add the optional [adk] extra, which the ADK path needs:
#       ADK_PRESENT=1 ./scripts/install.sh
#   Your real API key (it starts with bl_pk_) comes from
#   https://platform.bentolabs.ai.

# Stop immediately if any command fails, so problems are obvious.
set -euo pipefail

# 1. Decide which package to install.
#    The plain package is "bentolabs-sdk". The ADK path also needs the
#    "[adk]" extra, so we add that only when ADK_PRESENT is set to 1.
package="bentolabs-sdk"
if [ "${ADK_PRESENT:-0}" = "1" ]; then
  package="bentolabs-sdk[adk]"
fi

# 2. Install it using whatever package manager this project already uses.
#    We check for uv, then poetry, then pdm (all of which use
#    pyproject.toml), and fall back to plain pip if none of them is here.
if command -v uv >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  uv add "$package"
elif command -v poetry >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  poetry add "$package"
elif command -v pdm >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  pdm add "$package"
else
  pip install "$package"
fi

# 3. Make sure the .env file has a line for the API key.
#    We only add the placeholder if there isn't already a
#    BENTOLABS_API_KEY line, so we never overwrite a real key.
if [ ! -f .env ] || ! grep -q "^BENTOLABS_API_KEY=" .env; then
  echo 'BENTOLABS_API_KEY=bl_pk_...' >> .env
fi

# 4. Remind the human to replace the placeholder with their real key.
echo "Done. Now open .env and replace the placeholder with your real key"
echo "from https://platform.bentolabs.ai."
