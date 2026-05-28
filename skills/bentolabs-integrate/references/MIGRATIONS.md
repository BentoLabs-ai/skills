# Migrations

Reach this reference only after Step 1g found Raindrop or Langfuse AND the user explicitly picked **migrate** (not "fresh integration alongside"). If the user picked fresh, return to the greenfield Step 3 patterns and leave the old SDK in place.

Once you're here, pick the smoothest applicable path first. Manual per-call translation is the last resort. Full per-SDK translation tables and copy-prompt blocks live at:

- `https://docs.bentolabs.ai/migrations/raindrop.md`
- `https://docs.bentolabs.ai/migrations/langfuse.md`

## The three migration paths (apply in order, fall through on miss)

| Path | When it applies | How it works |
|---|---|---|
| **A — `bento.instrument()`** | App uses Google ADK | Three lines at startup. No per-call code. |
| **B — OpenInference instrumentor** | App used Raindrop's auto-instrumentation OR Langfuse's `langfuse.openai` / `langfuse.langchain` drop-ins | Register `openinference-instrumentation-<openai\|anthropic\|bedrock\|langchain>` with a `BentoLabsSpanProcessor`. Call sites stay untouched. |
| **C — manual translation** | Everything else | Per-call-site rename per the tables below. |

Most migrations end up using Path B for the bulk of the auto-captured LLM calls plus Path C for the handful of bespoke decorators or spans the old SDK had.

## Path A setup (Google ADK)

```bash
pip install "bentolabs-sdk[adk]"
```

```python
import bentolabs_sdk as bento

bento.init(
    user_id=lambda: get_current_user_id(),
    session_id=lambda: get_current_session_id(),
)
bento.instrument()
```

## Path B setup (OpenInference instrumentors)

Install the matching instrumentor(s) for each LLM SDK the migrator's app uses:

```bash
pip install openinference-instrumentation-openai
# Other libs as needed: -anthropic, -bedrock, -langchain, -llama-index
```

Register them once at app startup, against a `BentoLabsSpanProcessor`:

```python
from openinference.instrumentation.openai import OpenAIInstrumentor
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry import trace

from bentolabs_sdk import BentoLabsSpanProcessor

provider = TracerProvider()
provider.add_span_processor(BentoLabsSpanProcessor())
trace.set_tracer_provider(provider)

OpenAIInstrumentor().instrument(tracer_provider=provider)
# Repeat for AnthropicInstrumentor / BedrockInstrumentor / LangChainInstrumentor / etc.
```

After this:

- For Langfuse migrators: replace every `from langfuse.openai import OpenAI` with stock `from openai import OpenAI` (the instrumentor wraps the stock client). Drop `from langfuse.langchain import CallbackHandler`; the instrumentor takes its place.
- For Raindrop migrators: drop `raindrop.init(..., auto_instrument=True, instruments={...})`. The instrumentor replaces Traceloop's auto-capture; the LLM call sites stay untouched.

No `bento.track_ai` calls needed for anything Path B covers.

## From Raindrop (`raindrop-ai`, import `raindrop.analytics`)

1. `pip install bentolabs-sdk`. Do not uninstall Raindrop until verify passes.
2. **Path A first.** If ADK is in use, add `bento.init(...)` and `bento.instrument()` at startup. That captures ADK's runs immediately.
3. **Path B next.** Raindrop's `auto_instrument=True` covered OpenAI / Anthropic / Bedrock via Traceloop. Preserve that auto-capture by registering the matching OpenInference instrumentor with a `BentoLabsSpanProcessor`: `OpenAIInstrumentor().instrument(tracer_provider=provider)` and friends. Call sites stay untouched.
4. **Path C for the rest:**
   - Replace `import raindrop.analytics as raindrop` with `import bentolabs_sdk as bento`.
   - Replace `raindrop.init(write_key)` (or `api_key=`) with `bento.init(api_key=...)` or set `BENTOLABS_API_KEY`.
   - Add `provider="..."` to every remaining `bento.track_ai` call. Bento does not auto-infer provider.
   - Delete every `raindrop.identify(...)` and `raindrop.track_signal(...)` call. Move user traits to `properties=` or init-time `tags=`.
   - `@raindrop.task` becomes `@bento.tool`. Bento collapses task and tool into one kind.
5. Run the verification flow from Step 5. Then `pip uninstall raindrop-ai`.

Full translation table at `/migrations/raindrop.md`.

## From Langfuse (`langfuse`, v3 Python SDK)

1. `pip install bentolabs-sdk`. Do not uninstall Langfuse until verify passes.
2. **Path A first.** If ADK is in use, add `bento.init(...)` and `bento.instrument()` at startup.
3. **Path B next.** For each Langfuse drop-in or callback handler, register the matching OpenInference instrumentor with a `BentoLabsSpanProcessor`:
   - `from langfuse.openai import OpenAI` becomes `openinference-instrumentation-openai` (call sites use the stock `from openai import OpenAI`)
   - `from langfuse.langchain import CallbackHandler` becomes `openinference-instrumentation-langchain`
   - Anthropic, LlamaIndex, etc.: same pattern.
4. **Path C for the rest:**
   - Replace `Langfuse(public_key=..., secret_key=..., host=...)` / `get_client()` with `bento.init(api_key=...)`. Single key, format `bl_pk_...`, env var `BENTOLABS_API_KEY`.
   - `@observe()` on top-level handlers becomes `@bento.interaction`. `@observe()` on tool or helper functions becomes `@bento.tool`. `@observe(as_type="generation", ...)` becomes a `bento.track_ai(event=, model=, provider=, input=, output=)` call inside the body.
   - `propagate_attributes(user_id=, session_id=, tags=, metadata=)` becomes `bento.propagate_attributes(user_id=, session_id=, tags=)`. Drop `metadata=` (use `properties=` on per-call kwargs).
   - `langfuse.update_current_trace(metadata=...)` becomes `bento.update_current_trace(properties=...)`. Same rename for `update_current_observation` to `update_current_span`.
   - `session_id` is `session_id` on `init` / `begin` / `update_current_trace` / `propagate_attributes`, but **`convo_id` on `track_ai`**. The single biggest footgun.
   - Delete every `langfuse.score(...)`, `langfuse.get_prompt(...)`, and dataset call. No equivalents. Move score values to `properties={"score_<name>": value}`.
5. Run the verification flow from Step 5. Then `pip uninstall langfuse` and remove `LANGFUSE_*` env vars.

Full translation table at `/migrations/langfuse.md`.
