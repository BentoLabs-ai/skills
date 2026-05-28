# The three migration paths

Apply in order. Fall through on a miss. Most projects end up using **Path B** for the bulk of auto-captured LLM calls plus **Path C** for the handful of bespoke decorators or spans.

## Path A: `bento.instrument()` for Google ADK

Applies when the app uses Google ADK. Three lines at startup. Zero per-call code.

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

Every ADK agent run, tool call, and the LLM calls ADK makes are captured automatically. The user and session getters tag every span with `gen_ai.user.id` and `gen_ai.conversation.id`.

## Path B: OpenInference instrumentors

Applies when the source SDK auto-captured LLM calls. Common signals from `scripts/detect.sh`:

- **Raindrop**: `auto_instrument=True` in `raindrop.init(...)`.
- **Langfuse**: `from langfuse.openai import OpenAI`, `from langfuse.langchain import CallbackHandler`, or similar drop-ins.

Install the matching instrumentor for each LLM SDK the app uses. `scripts/install-instrumentors.sh` does this:

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

## Path C: Manual translation

Applies when neither Path A nor Path B covers the call site. Anything bespoke: custom decorators (`@observe(as_type="generation", ...)`, `@raindrop.task`), hand-rolled `track_ai` calls, score and metric reporting that the source SDK had but Bento doesn't.

Follow the per-SDK guide:

- **Raindrop**: `references/RAINDROP.md`
- **Langfuse**: `references/LANGFUSE.md`

Both guides walk import rename, init translation, decorator translation, and the convo_id / session_id naming.
