#!/usr/bin/env bash
#
# WHAT THIS DOES
#   Step 1 of the migration. It looks through the project and tells you
#   what tracing and agent tools it uses today, so you can pick a
#   migration path in Step 3.
#
# IT ONLY READS FILES. It changes nothing. Run it from the top folder of
# the project, and read each section of the output before deciding.
#
# HOW TO READ THE OUTPUT
#   - An agent SDK with its own exporter   -> Path A (direct export)
#   - An LLM SDK with an OpenInference one  -> Path B (instrumentor)
#   - Anything else (custom code)           -> Path C (manual)

# Don't stop on a failed search; some sections will find nothing, and
# that's fine.
set -uo pipefail

# Two small helpers so each search below is a single short line.
#   in_code  searches your source files (Python, TypeScript, JavaScript).
#   in_deps  searches the dependency lists (package.json, pyproject.toml,
#            requirements*.txt).
in_code() { grep -rn --include="*.py" --include="*.ts" --include="*.js" -iE "$1" . 2>/dev/null | head -20; }
in_deps() { grep -niE "$1" package.json pyproject.toml requirements*.txt 2>/dev/null; }

# Section 1: the OLD tracing tool you are replacing. If you see hits
# here, the project already uses Raindrop or Langfuse.
echo "--- Old tracing SDK you are migrating off (Raindrop / Langfuse) ---"
in_code "raindrop|from langfuse|import langfuse|@observe"
in_deps "raindrop|langfuse"

# Section 2: the agent / orchestration framework. If one of these is
# here, check it for a native exporter first (that's Path A, the best one).
echo
echo "--- Agent / orchestration SDK (check it for a native exporter, Path A) ---"
in_code "@mastra/|from mastra|openai-agents|@openai/agents|langchain|langgraph|llama_index|llamaindex|crewai|pydantic_ai|generateText|streamText"
in_deps "mastra|openai-agents|@openai/agents|langchain|langgraph|llama|crewai|pydantic-ai|\"ai\""

# Section 3: where traces go right now. These names tell you which
# exporter you might be able to repoint at Bento.
echo
echo "--- Where traces go now (existing exporter to reuse or repoint) ---"
in_code "ArizeExporter|OTLPSpanExporter|OTLPTraceExporter|OTEL_EXPORTER|phoenix|langsmith|LANGSMITH_OTEL"

# Section 4: raw LLM client libraries. These matter for the manual path
# (Path C) and for choosing instrumentors (Path B).
echo
echo "--- Raw LLM client SDK (for the manual path, Path C) ---"
in_code "openai|anthropic|bedrock-runtime|google\.genai|generativeai|vertexai"

# Section 5: Google ADK. If this is here, don't migrate it from this
# skill — use the simpler one-line [adk] path in bentolabs-integrate.
echo
echo "--- Google ADK (use the bentolabs-integrate [adk] path instead) ---"
in_code "google\.adk|from google\.adk|import google\.adk"
in_deps "google-adk"
