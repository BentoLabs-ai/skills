#!/usr/bin/env bash
# Step 1: Detect which AI observability SDK is in use.
#
# Walks the codebase looking for Raindrop and Langfuse usage. The output
# determines which translation guide to follow (RAINDROP.md or
# LANGFUSE.md) and which migration path applies (A, B, C).
#
# Run from the repo root.

echo "--- Raindrop ---"
# Raindrop (raindrop-ai, import raindrop.analytics)
grep -rnE "import raindrop|from raindrop|raindrop\.(init|track_ai|begin|identify|track_signal|flush|tool|task)|@raindrop\." --include="*.py" . 2>/dev/null
grep -nE "raindrop" pyproject.toml requirements*.txt 2>/dev/null

echo
echo "--- Langfuse ---"
# Langfuse (langfuse Python SDK v3)
grep -rnE "from langfuse|import langfuse|@observe|from langfuse\.(openai|langchain|anthropic|bedrock)|langfuse\.(score|get_prompt|update_current_trace|update_current_observation|propagate_attributes)" --include="*.py" . 2>/dev/null
grep -nE "^langfuse|^\s*langfuse" pyproject.toml requirements*.txt 2>/dev/null

echo
echo "--- Auto-capture signals (Path B candidates) ---"
# Raindrop auto_instrument
grep -rnE "auto_instrument\s*=\s*True|raindrop\.init\([^)]*auto_instrument" --include="*.py" . 2>/dev/null
# Langfuse drop-ins
grep -rnE "from langfuse\.(openai|langchain|anthropic|bedrock)" --include="*.py" . 2>/dev/null

echo
echo "--- Google ADK (Path A candidate) ---"
grep -rnE "from google\.adk|google\.adk\.|import google\.adk" --include="*.py" . 2>/dev/null
grep -nE "google-adk|google\.adk" pyproject.toml requirements*.txt 2>/dev/null
