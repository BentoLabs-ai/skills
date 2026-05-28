#!/usr/bin/env bash
#
# WHAT THIS DOES
#   Step 2 of the migration. It installs the Bento Python SDK next to
#   the old tracing SDK, and puts a placeholder for your API key in .env.
#
# WHEN TO RUN IT
#   Only for Path B (OpenInference instrumentor) or Path C (manual). The
#   direct-export path (Path A) installs nothing, so skip this script if
#   that's your path (see SKILL.md Step 3).
#
# BEFORE YOU RUN IT
#   If the app uses Google ADK, set ADK_PRESENT=1 first so the script
#   adds the optional [adk] extra:
#       ADK_PRESENT=1 ./scripts/install-bento.sh
#   Your real API key (it starts with bl_pk_) comes from
#   https://platform.bentolabs.ai.
#
# IMPORTANT
#   This does NOT remove the old SDK. Leave the old one installed until
#   the Step 5 verify passes — otherwise there's a window where nothing
#   is recording.

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

# 4. Remind the human what to do next.
echo "Done. Now open .env and replace the placeholder with your real key"
echo "from https://platform.bentolabs.ai."
echo "Keep the OLD SDK installed until the Step 5 verify passes."
