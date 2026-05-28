#!/usr/bin/env bash
# Path B helper: install OpenInference instrumentors for the LLM SDKs in use.
#
# Pass the LLM SDK names as arguments. Each maps to an
# openinference-instrumentation-<name> package on PyPI.
#
# Common values: openai, anthropic, bedrock, langchain, llama-index,
# google-genai, mistralai, groq.
#
# Examples:
#   ./install-instrumentors.sh openai anthropic
#   ./install-instrumentors.sh langchain llama-index
#
# These are the auto-capture libraries that replace Raindrop's
# auto_instrument and Langfuse's drop-in clients (langfuse.openai,
# langfuse.langchain, etc).

set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <sdk> [<sdk> ...]"
  echo "       e.g. $0 openai anthropic langchain"
  exit 2
fi

PKGS=()
for sdk in "$@"; do
  PKGS+=("openinference-instrumentation-${sdk}")
done

if command -v uv >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  uv add "${PKGS[@]}"
elif command -v poetry >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  poetry add "${PKGS[@]}"
elif command -v pdm >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  pdm add "${PKGS[@]}"
else
  pip install "${PKGS[@]}"
fi

echo
echo "Now wire the instrumentors into a TracerProvider with BentoLabsSpanProcessor."
echo "See references/PATHS.md for the Path B snippet."
