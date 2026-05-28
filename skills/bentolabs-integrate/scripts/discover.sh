#!/usr/bin/env bash
# Step 1: Discover the codebase before instrumenting.
#
# Run each section from the repo root. The output drives every later
# decision (which web framework, which LLM SDKs, whether Google ADK is
# in use, whether OpenTelemetry is already wired, whether a competing
# SDK like Raindrop or Langfuse is installed). Do NOT skip this step.
#
# Output is the input to Step 1h ("summarize before continuing").

# 1a. Confirm language and Python version.
echo "--- 1a: language / Python ---"
ls pyproject.toml setup.py setup.cfg requirements.txt requirements*.txt 2>/dev/null
grep -E '^\s*(python|requires-python)\s*=' pyproject.toml 2>/dev/null
python3 --version 2>/dev/null

# 1b. Detect the web framework. The framework's request object is where
#     user_id and convo_id typically live.
echo "--- 1b: web framework ---"
grep -rlE "from fastapi|FastAPI\(|@app\.(get|post|put|delete)" --include="*.py" . 2>/dev/null | head -5
grep -rlE "from flask|Flask\(|@app\.route" --include="*.py" . 2>/dev/null | head -5
grep -rlE "from django|django\.|DJANGO_SETTINGS" --include="*.py" . 2>/dev/null | head -5
grep -rlE "from starlette|Starlette\(" --include="*.py" . 2>/dev/null | head -5

# 1c. Find every LLM call site. Read each match before deciding the
#     pattern; the call is sometimes inside a helper that already has a
#     clean wrap point.
echo "--- 1c: LLM call sites ---"
# OpenAI (sync + async clients, completions and responses APIs)
grep -rnE "openai\.|OpenAI\(|AsyncOpenAI\(|\.chat\.completions\.create|\.responses\.create|\.completions\.create" --include="*.py" . 2>/dev/null
# Anthropic
grep -rnE "anthropic\.|Anthropic\(|AsyncAnthropic\(|\.messages\.create|\.completions\.create" --include="*.py" . 2>/dev/null
# Google (Gemini / Vertex)
grep -rnE "google\.genai|google\.generativeai|GenerativeModel|generate_content|vertexai" --include="*.py" . 2>/dev/null
# AWS Bedrock (provider must be aws_bedrock, not the vendor)
grep -rnE "bedrock-runtime|invoke_model|converse" --include="*.py" . 2>/dev/null
# Agent frameworks
grep -rnE "ChatOpenAI|ChatAnthropic|ChatGoogleGenerativeAI|llm\.(invoke|ainvoke|predict|apredict)|\.bind_tools\(" --include="*.py" . 2>/dev/null
grep -rnE "from llama_index|Settings\.llm|VectorStoreIndex|query_engine" --include="*.py" . 2>/dev/null

# 1d. Check for Google ADK. PRIORITY SIGNAL for Step 3.
#     If ADK is present, Step 3 Path A applies: a three-line install
#     replaces most per-call-site wrapping.
echo "--- 1d: Google ADK ---"
grep -rnE "from google\.adk|google\.adk\.|import google\.adk" --include="*.py" . 2>/dev/null
grep -nE "google-adk|google\.adk" pyproject.toml requirements*.txt 2>/dev/null

# 1e. Check for existing OpenTelemetry setup. If a TracerProvider is
#     already configured, prefer the OTel transport path (see
#     references/REFERENCE.md "Lower-level: the OTel transport").
echo "--- 1e: existing OpenTelemetry ---"
grep -rnE "TracerProvider|set_tracer_provider|add_span_processor|trace\.get_tracer" --include="*.py" . 2>/dev/null
grep -nE "opentelemetry|otlp|OTLPSpanExporter" pyproject.toml requirements*.txt 2>/dev/null

# 1f. Find environment-variable config. The env file is where
#     BENTOLABS_API_KEY should be added.
echo "--- 1f: env / config ---"
find . -maxdepth 3 \( -name ".env*" -o -name "settings.py" -o -name "config.py" -o -name "config.yaml" -o -name "config.toml" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null
grep -rnE "load_dotenv|from dotenv|pydantic_settings|BaseSettings" --include="*.py" . 2>/dev/null | head -5

# 1g. Detect competing SDKs (Raindrop, Langfuse).
#     If anything matches here, ASK the user before proceeding. The
#     answer (migrate vs fresh integration alongside) changes Step 3
#     fundamentally. See the "Existing competing SDK" section in SKILL.md.
echo "--- 1g: competing SDKs ---"
# Raindrop (raindrop-ai, import raindrop.analytics)
grep -rnE "import raindrop|from raindrop|raindrop\.(init|track_ai|begin|identify|track_signal|flush)" --include="*.py" . 2>/dev/null
grep -nE "raindrop" pyproject.toml requirements*.txt 2>/dev/null
# Langfuse (langfuse Python SDK v3)
grep -rnE "from langfuse|import langfuse|@observe|from langfuse\.(openai|langchain)" --include="*.py" . 2>/dev/null
grep -nE "^langfuse|^\s*langfuse" pyproject.toml requirements*.txt 2>/dev/null
