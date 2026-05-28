# Path A: direct export (no Bento SDK)

This is the first choice and the simplest. Bento is just an OpenTelemetry
collector, so if your agent SDK already has its own OpenTelemetry /
OpenInference exporter, you point that exporter at Bento and install
nothing. The technical name is **direct OTLP export to an OTLP-compatible
backend**.

Every such exporter needs exactly two settings:

1. **Endpoint** — `${BENTOLABS_BASE_URL}/v1/traces` (base URL defaults to
   `https://api.bentolabs.ai`).
2. **Auth header** — `Authorization: Bearer ${BENTOLABS_API_KEY}` (the key
   starts with `bl_pk_`).

Bento accepts OTLP/HTTP in both protobuf and JSON, and reads both
`gen_ai.*` and `openinference.*` span attributes. So any standard OTLP
exporter works — the only thing to confirm per SDK is that it can send a
`Bearer` header and that it emits one of those attribute sets.

## Which SDKs support this

| SDK | Direct export? | How | What fills columns | If it can't |
|---|---|---|---|---|
| **Mastra** (TS) | Yes | `ArizeExporter({ endpoint, apiKey })` | `openinference.*` | `@arizeai/openinference-mastra` |
| **Vercel AI SDK** (TS) | Yes | `@vercel/otel` OTLP exporter + `experimental_telemetry` on each call | `gen_ai.*` (model, tokens) | add `@arizeai/openinference-vercel` for prompt/response text |
| **LangChain / LangGraph** | Yes | `langsmith[otel]`: set `LANGSMITH_OTEL_ENABLED=true` + OTLP env vars | `gen_ai.*` | `openinference-instrumentation-langchain` (Path B) |
| **Pydantic AI** | Yes | `Agent.instrument_all()` + a standard OTLP exporter | `gen_ai.*` | `openinference-instrumentation-pydantic-ai` |
| **Claude Agent SDK** | Yes (beta) | Claude Code OTel env vars + Bearer | `gen_ai.*` (partial) | `openinference-instrumentation-claude-agent-sdk` |
| **LlamaIndex** | Transport only | needs its instrumentor to emit readable attributes | — | `openinference-instrumentation-llama-index` (Path B) |
| **OpenAI Agents SDK** | No | its built-in tracing is OpenAI-proprietary, not OTLP | — | Python: `openinference-instrumentation-openai-agents` (Path B); JS: manual |
| **CrewAI** | No | built-in telemetry is anonymous usage analytics, no LLM I/O | — | `openinference-instrumentation-crewai` (Path B) |

If your SDK isn't listed, the rule still holds: if it has an OTLP /
OpenInference exporter you can point at an arbitrary URL with a `Bearer`
header, use it here; otherwise drop to Path B.

## TypeScript / JavaScript

Direct export installs no Bento SDK, so it works from any language — the
"Bento TypeScript SDK is not GA" caveat does **not** apply here. Mastra
and the Vercel AI SDK are the common TS cases.

## Example: Mastra (TypeScript)

```ts
import { Observability } from '@mastra/core';
import { ArizeExporter } from '@mastra/arize';

export const observability = new Observability({
  configs: {
    bento: {
      exporters: [
        new ArizeExporter({
          endpoint: `${process.env.BENTOLABS_BASE_URL ?? 'https://api.bentolabs.ai'}/v1/traces`,
          apiKey: process.env.BENTOLABS_API_KEY, // bl_pk_...
        }),
      ],
    },
  },
});
```

**Gotcha:** `ArizeExporter` only sends `Authorization: Bearer` when
`spaceId` is absent. If `spaceId` is set, OR `ARIZE_SPACE_ID` exists in the
environment, it silently switches to Arize's own `space_id` / `api_key`
headers and Bento rejects the traces with no obvious error. Leave
`spaceId` unset and make sure `ARIZE_SPACE_ID` is not exported.

## Example: any OpenTelemetry / OpenInference SDK (Python)

```python
import os
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

base = os.environ.get("BENTOLABS_BASE_URL", "https://api.bentolabs.ai")
exporter = OTLPSpanExporter(
    endpoint=f"{base}/v1/traces",
    headers={"Authorization": f"Bearer {os.environ['BENTOLABS_API_KEY']}"},
)
provider = TracerProvider()
provider.add_span_processor(BatchSpanProcessor(exporter))
trace.set_tracer_provider(provider)

# Then turn on your SDK's instrumentation, e.g.:
#   from pydantic_ai.agent import Agent;            Agent.instrument_all()
#   from openinference.instrumentation.langchain import LangChainInstrumentor
#   LangChainInstrumentor().instrument(tracer_provider=provider)
```

The same two settings can also come from environment variables, with no
code:

```
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=https://api.bentolabs.ai/v1/traces
OTEL_EXPORTER_OTLP_HEADERS=Authorization=Bearer bl_pk_...
```

## Verify the same six columns

Direct export gets traces flowing, but a trace arriving is not the same as
the dashboard being filled in. If the SDK emits different attribute names,
columns stay empty. After wiring it up, run one real flow and confirm
`provider`, `model`, `input`, `output`, `user_id`, `convo_id` are all
populated (Step 5). If `input` / `output` are empty, the SDK emits metadata
but not content — add its OpenInference instrumentor (the "If it can't"
column) on the same exporter to fill them.

The `user_id` / `convo_id` columns come from two plain span attributes —
`gen_ai.user.id` and `gen_ai.conversation.id`. On this path there is no
Bento SDK, so set them through your own framework (a run attribute, a span
processor, or OTLP resource attributes), not `bento.init` getters. Full
attribute → column table: `https://docs.bentolabs.ai/python/otel-transport.md`.
