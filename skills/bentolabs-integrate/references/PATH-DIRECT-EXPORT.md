# Direct export: no Bento SDK

The simplest greenfield path. Bento is an OpenTelemetry collector, so if
the app already builds on an agent SDK that ships its own OTel /
OpenInference exporter, you point that exporter at Bento and install no
Bento SDK at all. The technical name is **direct OTLP export to an
OTLP-compatible backend**.

Prefer this when you control the framework choice — picking an SDK that
emits standard OpenTelemetry spans means Bento (and any other OTel
backend) reads them with zero per-call-site code.

Every such exporter needs exactly two settings:

1. **Endpoint** — `${BENTOLABS_BASE_URL}/v1/traces` (base URL defaults to
   `https://api.bentolabs.ai`).
2. **Auth header** — `Authorization: Bearer ${BENTOLABS_API_KEY}` (the key
   starts with `bl_pk_`).

Bento accepts OTLP/HTTP in both protobuf and JSON and reads both
`gen_ai.*` and `openinference.*` attributes, so any standard OTLP exporter
works. The only thing to confirm per SDK is that it can send a `Bearer`
header and emits one of those attribute sets.

## Which SDKs support this

| SDK | Direct export? | How | If it can't |
|---|---|---|---|
| **LangChain / LangGraph** | Yes | `langsmith[otel]`: `LANGSMITH_OTEL_ENABLED=true` + OTLP env vars | `openinference-instrumentation-langchain` |
| **Pydantic AI** | Yes | `Agent.instrument_all()` + a standard OTLP exporter | `openinference-instrumentation-pydantic-ai` |
| **Mastra** (TS) | Yes | `ArizeExporter({ endpoint, apiKey })` (leave `spaceId` unset) | `@arizeai/openinference-mastra` |
| **Vercel AI SDK** (TS) | Yes | `@vercel/otel` OTLP exporter + `experimental_telemetry` per call | `@arizeai/openinference-vercel` for prompt/response text |
| **LlamaIndex** | Transport only | needs its OpenInference instrumentor to emit readable attributes | `openinference-instrumentation-llama-index` |
| **OpenAI Agents SDK** | No | its built-in tracing is OpenAI-proprietary, not OTLP | Python: `openinference-instrumentation-openai-agents`; JS: manual |
| **CrewAI** | No | built-in telemetry is anonymous usage analytics | `openinference-instrumentation-crewai` |

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
#   from pydantic_ai.agent import Agent;  Agent.instrument_all()
```

The same two settings can come from environment variables, with no code:

```
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=https://api.bentolabs.ai/v1/traces
OTEL_EXPORTER_OTLP_HEADERS=Authorization=Bearer bl_pk_...
```

## TypeScript / JavaScript

Direct export installs no Bento SDK, so it works from any language — the
"Bento TypeScript SDK is not GA" caveat does **not** apply here. Mastra and
the Vercel AI SDK are the common TS cases; see the Mastra example in the
`bentolabs-migrate` skill's `references/NATIVE-EXPORT.md`.

## Then verify the same six columns

Traces arriving is not the same as the dashboard filling in. After wiring
the exporter, run one real flow and confirm `provider`, `model`, `input`,
`output`, `user_id`, `convo_id` are all populated (Step 5). If `input` /
`output` are empty, the SDK emits metadata but not content — add its
OpenInference instrumentor (the "If it can't" column) on the same exporter.

Identity (`user_id` / `convo_id` columns) comes from two plain span
attributes — `gen_ai.user.id` and `gen_ai.conversation.id`. On this path
there is no Bento SDK, so set them through your own framework, not
`bento.init` getters: most agent SDKs let you attach attributes or
metadata to a run, and a span processor or the OTLP resource attributes
can stamp them on every span. The full attribute → column table is at
`https://docs.bentolabs.ai/python/otel-transport.md`.
