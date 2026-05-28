# The three migration paths

Apply in order, fall through on a miss. Agent-SDK migrations usually end on **Path A**. Raindrop/Langfuse migrations usually end on **Path B** for the auto-captured calls plus **Path C** for the bespoke ones.

**Using Google ADK?** Don't migrate it here — the one-line `bentolabs-sdk[adk]` auto-instrument path in the `bentolabs-integrate` skill is simpler.

## Path A: direct export (no Bento SDK)

Applies when the agent SDK has its own OpenTelemetry / OpenInference exporter that can point at an arbitrary endpoint with a `Bearer` header. You repoint it at Bento and install nothing.

This is the first choice. The full per-SDK support matrix and config snippets (Mastra, Vercel AI SDK, LangChain, Pydantic AI, and the generic OpenTelemetry form) live in **`references/NATIVE-EXPORT.md`**.

## Path B: OpenInference instrumentor

Applies when there's no native exporter but the source SDK auto-captured LLM calls. Common signals from `scripts/detect.sh`:

- **Raindrop**: `auto_instrument=True` in `raindrop.init(...)`.
- **Langfuse**: `from langfuse.openai import OpenAI`, `from langfuse.langchain import CallbackHandler`, or similar drop-ins.

Install the matching instrumentor for each LLM SDK. `scripts/install-instrumentors.sh` does this:

```bash
./scripts/install-instrumentors.sh openai anthropic langchain
```

Register them once at app startup, against a `BentoLabsSpanProcessor`:

```python
from openinference.instrumentation.openai import OpenAIInstrumentor
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider

from bentolabs_sdk import BentoLabsSpanProcessor

provider = TracerProvider()
provider.add_span_processor(BentoLabsSpanProcessor())
trace.set_tracer_provider(provider)

OpenAIInstrumentor().instrument(tracer_provider=provider)
# Repeat for AnthropicInstrumentor / BedrockInstrumentor / LangChainInstrumentor / etc.
```

After this:

- **Langfuse migrators**: replace every `from langfuse.openai import OpenAI` with stock `from openai import OpenAI`. Drop `from langfuse.langchain import CallbackHandler`; the instrumentor replaces it.
- **Raindrop migrators**: drop `raindrop.init(..., auto_instrument=True, instruments={...})`. The instrumentor replaces Traceloop's auto-capture. LLM call sites stay untouched.

No `bento.track_ai` calls needed for anything Path B covers.

`BentoLabsSpanProcessor` is the Python span processor. If you already run your own `TracerProvider` and just want the exporter, use `BentoLabsTraceExporter` directly (see `https://docs.bentolabs.ai/python/otel-transport.md`).

## Path C: manual translation

Applies when neither Path A nor Path B covers the call site. Anything bespoke: custom decorators (`@observe(as_type="generation", ...)`, `@raindrop.task`), hand-rolled `track_ai` calls, score and metric reporting the source SDK had but Bento doesn't.

Follow the per-SDK guide:

- **Raindrop**: `references/RAINDROP.md`
- **Langfuse**: `references/LANGFUSE.md`

Both guides walk the import rename, init translation, decorator translation, and the `convo_id` / `session_id` naming. Remember: `track_ai` and `begin` take `convo_id=`; everywhere else takes `session_id=`.
