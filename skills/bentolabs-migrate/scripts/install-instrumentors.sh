#!/usr/bin/env bash
#
# WHAT THIS DOES
#   Path B helper. It installs the OpenInference instrumentor packages
#   for the LLM SDKs you name. These packages auto-capture the LLM calls
#   your app makes, so you don't have to add a Bento call at every site.
#   They replace Raindrop's auto_instrument and Langfuse's drop-in clients.
#
# HOW TO RUN IT
#   Pass one or more SDK names. Each name turns into a package called
#   openinference-instrumentation-<name>. For example:
#       ./install-instrumentors.sh openai anthropic
#       ./install-instrumentors.sh langchain llama-index
#   Common names: openai anthropic bedrock langchain llama-index
#                 google-genai mistralai groq
#
# AFTER IT FINISHES
#   You still have to turn the instrumentors on by registering them on a
#   BentoLabsSpanProcessor. The code for that is in references/PATHS.md,
#   under Path B.

# Stop immediately if any command fails, so problems are obvious.
set -euo pipefail

# 1. Make sure the caller actually named at least one SDK.
if [ "$#" -eq 0 ]; then
  echo "usage: $0 <sdk> [<sdk> ...]   e.g. $0 openai anthropic langchain"
  exit 2
fi

# 2. Turn each SDK name into its full instrumentor package name.
#    "openai" -> "openinference-instrumentation-openai", and so on.
packages=()
for sdk in "$@"; do
  packages+=("openinference-instrumentation-${sdk}")
done

# 3. Install them all using whatever package manager this project uses.
#    We check uv, then poetry, then pdm (all use pyproject.toml), and
#    fall back to plain pip if none of them is here.
if command -v uv >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  uv add "${packages[@]}"
elif command -v poetry >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  poetry add "${packages[@]}"
elif command -v pdm >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  pdm add "${packages[@]}"
else
  pip install "${packages[@]}"
fi

# 4. Point the human at the next step.
echo "Done. Now turn the instrumentors on — see references/PATHS.md, Path B."
