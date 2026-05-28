# Reference

Deep reference for the public surface, the four kwargs, trajectories, properties, lifecycle, and the lower-level OTel transport.

## Integration surface

Public API on `bentolabs_sdk` (not `.analytics`):

| Call | Effect |
|---|---|
| `bento.instrument()` | Auto-detect and activate the Google ADK integration. Returns `"adk"` or `None`. |
| `bento.instrument("adk")` | Explicit pick. Raises `ValueError` on unknown names. Logs a warning and returns `None` if the extra isn't installed. |
| `bento.uninstrument()` | Reverse every active integration. Returns the names removed as `list[str]`. |
| `bento.uninstrument("adk")` | Specific reverse. |

Currently supported names: `"adk"`. Install with `pip install "bentolabs-sdk[adk]"`.

One-integration-at-a-time invariant: a second `instrument()` with a different target while one is active logs a warning and is ignored. Call `uninstrument(name)` first to switch.

Bento never calls `trace.set_tracer_provider()`. Every integration is passed `tracer_provider=` explicitly, so the host app's existing OTel stack keeps working.

## Identity getters at `init()`

`bento.init(user_id=..., session_id=..., tags=...)` accepts:

- A static value (single-tenant apps): `bento.init(user_id="org_42")`.
- A zero-arg callable (per-request apps): `bento.init(user_id=lambda: current_user.get())`.
- Omitted: keep whatever was previously registered (partial `init()` preserves identity).
- Explicit `None`: clear that field's source.

Bento invokes the callable on every span and writes the result to `gen_ai.user.id` / `gen_ai.conversation.id` / `langfuse.tags`. ADK integration-captured spans get tagged the same way; no per-call-site code.

A getter that raises is swallowed. The field is dropped for that span and the host app is never affected.

## Late-binding identity

| Call | Targets |
|---|---|
| `bento.update_current_trace(user_id=, session_id=, tags=, properties=)` | The open `bento.begin(...)` trajectory's root span. No-op if no trajectory is open. |
| `bento.update_current_span(properties=)` | The innermost open OTel span (a tool span, a framework span captured by an integration, or the trajectory root). |
| `with bento.propagate_attributes(user_id=, session_id=, tags=): ...` | Per-task scope. Takes precedence over init-time getters. Restores on exit. |

## The four kwargs that must be on every call

Skipping any of these silently disables a dashboard feature.

| Kwarg | What breaks if you skip it |
|---|---|
| `user_id` | User filter and per-user breakdowns. No profile data is stored; this is a pass-through string. |
| `convo_id` | Multi-turn conversations look like N independent rows. The same value across every turn links them. |
| `model` | Cost view and per-model breakdown. Spend rolls up under "Unknown". |
| `provider` | Provider filter and grouping. **Not auto-inferred from the model name.** |

`provider` is the most common omission. Common values: `openai`, `anthropic`, `google`, `aws_bedrock`, `azure_openai`, `cohere`, `mistral`. A Bedrock model id like `anthropic.claude-3-sonnet-20240229-v1:0` needs `provider="aws_bedrock"`, NOT `"anthropic"`.

## Multi-step work: trajectories

A trajectory is one OTel span that stays open across an agent turn or a multi-step task. Subsequent `track_ai` and `tool_span` calls in the same task parent to it, so the whole flow renders as one trace. See `PATH-B-MANUAL.md` Pattern B for the canonical shape.

`@bento.tool` auto-captures bound arguments as `input.value` and the return value as `output.value`. `@bento.interaction` captures the return value as `output.value` but does NOT auto-capture arguments (often non-trivial to serialize, frequently sensitive). Call `interaction.update(input=...)` from inside the function if you need the input recorded.

Trajectory rules to encode:

- `track_ai` and `begin` detach from any outer OTel context on purpose. That keeps a Bento span out of the caller's FastAPI / Django trace. Do not "fix" this by reattaching; the ingest mapper depends on it.
- Nested trajectories must be finished in reverse open order. Out-of-order `finish()` raises `RuntimeError`. Always use the `with bento.begin(...) as i:` form when nesting.
- Threads and `concurrent.futures` workers do not inherit the trajectory `ContextVar`. Wrap submit calls with `contextvars.copy_context().run(...)` to inherit the trajectory. `asyncio` tasks inherit automatically.

## Custom dimensions: `properties=`

```python
bento.track_ai(
    event="search",
    properties={"feature": "semantic_search", "experiment_id": 7, "is_premium": True},
    user_id="u1", convo_id="c1", model="gpt-4o", provider="openai",
)
```

Property values keep their type. `int`, `float`, `bool`, `str`, and homogeneous lists pass through with type intact, so the dashboard can filter `experiment_id > 100` or `is_premium = true`. Dicts and mixed lists fall back to JSON strings.

`properties` is also accepted by `bento.begin(...)`, `interaction.update(...)`, `interaction.finish(...)`, `bento.tool_span(...)`, and `interaction.tool_span(...)`.

Do not put `gen_ai.*`, `input.value`, or `output.value` keys inside `properties`. The SDK-managed kwargs are written after properties and will overwrite them.

## Lifecycle and flush

The SDK ships spans on a background daemon thread. The hot path costs roughly 10 microseconds per call; the HTTP POST happens off-thread.

| Scenario | What to do |
|---|---|
| Long-running service (FastAPI, Django, worker) | Nothing. `atexit` flushes on clean exit. |
| Short script, notebook, Lambda handler | Call `bento.flush()` before exit, or the last batch is dropped. |
| `os._exit`, `SIGKILL`, hard process kill | `atexit` is bypassed. The queue is lost. Always `flush()` first. |
| Rotating credentials | `bento.shutdown()` then `bento.init(api_key="bl_pk_new...")`. |

Calling `bento.init()` twice with conflicting credentials raises `BentoAuthError("already_initialized")`. Call `shutdown()` to rotate.

## Lower-level: the OTel transport

If the app already has a `TracerProvider`, skip the analytics layer and wire the Bento exporter into the existing pipeline.

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from bentolabs_sdk import BentoLabsSpanProcessor

provider = TracerProvider()
provider.add_span_processor(BentoLabsSpanProcessor())
trace.set_tracer_provider(provider)
```

For the same dashboard columns the analytics layer fills, upstream spans must carry:

| Set this attribute | Lands in dashboard column |
|---|---|
| `span.name` (via `tracer.start_span(name)`) | Span name |
| `gen_ai.user.id` | User |
| `gen_ai.conversation.id` | Session |
| `gen_ai.request.model` | Model |
| `gen_ai.system` | Provider |
| `input.value` | Input |
| `output.value` | Output |
| `openinference.span.kind="tool"` | Span kind (tool icon and filter) |
