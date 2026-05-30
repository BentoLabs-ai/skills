# Direct export

The idea: Bento is an OpenTelemetry collector. If the app is built on a framework that already has its own OpenTelemetry exporter, you point that exporter at Bento. The two settings every such exporter needs are:

1. **Endpoint** — `${BENTOLABS_BASE_URL}/v1/traces` (base URL defaults to `https://api.bentolabs.ai`).
2. **Auth header** — `Authorization: Bearer ${BENTOLABS_API_KEY}` (the key starts with `bl_pk_`).

## The one rule that decides everything: Bento needs JSON

Bento's ingest accepts **OTLP/HTTP with a JSON payload only** (gzip is fine). It does **not** accept protobuf yet — a protobuf request comes back as `415 Unsupported Media Type`. So the exporter must be configured for `http/json`.

This splits the path by language:

- **TypeScript / JavaScript** — direct export works with **no Bento SDK**, because JS OpenTelemetry exporters can emit JSON. This is the real "install nothing" path.
- **Python** — there is **no no-SDK path today**, because the stock Python OpenTelemetry exporters only emit protobuf, which Bento rejects. Python frameworks instead use the Bento SDK's JSON span processor (`BentoLabsSpanProcessor`) plus an OpenInference instrumentor. (The Bento SDK ships its own JSON exporter precisely because stock Python OTel can't emit JSON.)

Bento reads `gen_ai.*` and `openinference.*` attributes, so the dashboard columns fill from whichever of those your framework emits.

## TypeScript — no Bento SDK

### Vercel AI SDK

Use `@vercel/otel`'s `OTLPHttpJsonTraceExporter` (it sends JSON):

```ts
// instrumentation.ts
import { registerOTel, OTLPHttpJsonTraceExporter } from "@vercel/otel";

export function register() {
  registerOTel({
    serviceName: "my-app",
    traceExporter: new OTLPHttpJsonTraceExporter({
      url: `${process.env.BENTOLABS_BASE_URL ?? "https://api.bentolabs.ai"}/v1/traces`,
      headers: { Authorization: `Bearer ${process.env.BENTOLABS_API_KEY}` },
    }),
  });
}
```

Then set `experimental_telemetry: { isEnabled: true }` on each `generateText` / `streamText` call. The AI SDK emits `gen_ai.*` (model, tokens). Prompt/response text lives under `ai.*`; add `@arizeai/openinference-vercel` to fill the input/output columns.

### Mastra

Use Mastra's `OtelExporter` with `protocol: "http/json"`:

```ts
import { OtelExporter } from "@mastra/otel-exporter";

new OtelExporter({
  provider: {
    custom: {
      endpoint: `${process.env.BENTOLABS_BASE_URL ?? "https://api.bentolabs.ai"}/v1/traces`,
      protocol: "http/json",
      headers: { Authorization: `Bearer ${process.env.BENTOLABS_API_KEY}` },
    },
  },
});
```

**Caveat on `ArizeExporter`.** Mastra's `ArizeExporter` preset maps to OpenInference, but it may send protobuf (which Bento rejects) and it switches to Arize's own headers if `ARIZE_SPACE_ID` is set. Prefer the `OtelExporter` with `protocol: "http/json"` above, and verify the columns fill afterward.

## Python — with the Bento span processor

Because Bento needs JSON and stock Python OTel exporters send protobuf, Python frameworks attach the Bento SDK's JSON span processor plus an OpenInference instrumentor. Call sites stay untouched.

```bash
pip install bentolabs-sdk openinference-instrumentation-langchain
```

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from openinference.instrumentation.langchain import LangChainInstrumentor

from bentolabs_sdk import BentoLabsSpanProcessor  # sends JSON to Bento

provider = TracerProvider()
provider.add_span_processor(BentoLabsSpanProcessor())
trace.set_tracer_provider(provider)

LangChainInstrumentor().instrument(tracer_provider=provider)
```

Swap the instrumentor for your framework — `openinference-instrumentation-llama-index`, `-openai-agents`, `-crewai`, `-anthropic`, etc. This applies even to frameworks that emit OpenTelemetry natively (e.g. Pydantic AI's `Agent.instrument_all()`): they still need a JSON exporter, so attach `BentoLabsSpanProcessor`. See `references/REFERENCE.md` for the processor details.

## Which framework, which path

| Framework | Language | How |
|---|---|---|
| Vercel AI SDK | TS | `@vercel/otel` `OTLPHttpJsonTraceExporter` — no Bento SDK |
| Mastra | TS | `OtelExporter` with `protocol: "http/json"` — no Bento SDK |
| LangChain / LangGraph | Python | OpenInference instrumentor + `BentoLabsSpanProcessor` |
| LlamaIndex | Python | OpenInference instrumentor + `BentoLabsSpanProcessor` |
| Pydantic AI | Python | `Agent.instrument_all()` + `BentoLabsSpanProcessor` |
| OpenAI Agents SDK | Python | OpenInference instrumentor + `BentoLabsSpanProcessor` (built-in tracing is not OTLP) |
| CrewAI | Python | OpenInference instrumentor + `BentoLabsSpanProcessor` |

## Verify the six columns

Traces arriving is not the same as the dashboard filling in. After wiring it up, run one real flow and confirm `provider`, `model`, `input`, `output`, `user_id`, `convo_id` are all populated. If `input` / `output` are empty, the framework emits metadata but not content — add its OpenInference instrumentor (Python) or `@arizeai/openinference-vercel` (Vercel).

Identity (`user_id` / `convo_id`) comes from the `gen_ai.user.id` and `gen_ai.conversation.id` span attributes. With no Bento SDK (TypeScript), set them through your framework — a run attribute, a span processor, or OTLP resource attributes.
