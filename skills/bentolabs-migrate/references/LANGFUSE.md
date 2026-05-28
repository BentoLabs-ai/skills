# Migrating from Langfuse (`langfuse` Python SDK v3)

For users of the Langfuse Python SDK v3 (`from langfuse`, `@observe`, `langfuse.openai`, etc). Full translation table is at `https://docs.bentolabs.ai/migrations/langfuse.md`.

## Step order

1. `pip install bentolabs-sdk`. Do not uninstall `langfuse` yet.
2. **Path A first.** If Google ADK is in use, add `bento.init(...)` + `bento.instrument()` at startup. See `references/PATHS.md` Path A.
3. **Path B next.** For each Langfuse drop-in or callback handler, install the matching OpenInference instrumentor and wire it to a `BentoLabsSpanProcessor`. See `references/PATHS.md` Path B.
4. **Path C for the rest.** Walk the renames below for every remaining `@observe` and helper call.
5. Run `scripts/verify.py`. Confirm the row lands. THEN `pip uninstall langfuse` and remove `LANGFUSE_*` env vars.

## Per-call rename

### Drop-in clients (Path B)

After installing the matching OpenInference instrumentor:

```python
# Before
from langfuse.openai import OpenAI
client = OpenAI()

# After
from openai import OpenAI       # stock client
client = OpenAI()
# The OpenAIInstrumentor (registered at startup) wraps it automatically.
```

Same pattern for `from langfuse.langchain import CallbackHandler` (drop it; `LangChainInstrumentor` replaces it), `from langfuse.anthropic`, etc.

### Init and credentials

```python
# Before
from langfuse import Langfuse
langfuse = Langfuse(
    public_key="pk-lf-...",
    secret_key="sk-lf-...",
    host="https://cloud.langfuse.com",
)
# or
from langfuse import get_client
langfuse = get_client()

# After
import bentolabs_sdk as bento
bento.init(api_key="bl_pk_...")    # or set BENTOLABS_API_KEY env var
```

Single key, prefix `bl_pk_`. Env var: `BENTOLABS_API_KEY`. Drop `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `LANGFUSE_HOST`.

### `@observe` decorator

Langfuse's `@observe()` does three different things depending on context. Map each to the right Bento equivalent.

| Langfuse usage | Bento equivalent |
|---|---|
| `@observe()` on a top-level handler (request, agent turn) | `@bento.interaction` |
| `@observe()` on a tool or helper function | `@bento.tool` |
| `@observe(as_type="generation", ...)` on an LLM-calling function | Replace the body with a `bento.track_ai(event=, model=, provider=, input=, output=)` call |

```python
# Before
from langfuse import observe

@observe()
def handle_message(text: str) -> str: ...

@observe(as_type="generation", name="generate_reply", model="gpt-4o")
def generate_reply(prompt: str) -> str:
    return openai_call(prompt)

# After
import bentolabs_sdk as bento

@bento.interaction
def handle_message(text: str) -> str: ...

def generate_reply(prompt: str) -> str:
    reply = openai_call(prompt)
    bento.analytics.track_ai(
        event="generate_reply",
        user_id=..., convo_id=...,
        model="gpt-4o", provider="openai",
        input=prompt, output=reply,
    )
    return reply
```

### `langfuse.update_current_trace` and `langfuse.update_current_observation`

```python
# Before
langfuse.update_current_trace(metadata={"plan": "pro"})
langfuse.update_current_observation(metadata={"latency_ms": 320})

# After
bento.update_current_trace(properties={"plan": "pro"})
bento.update_current_span(properties={"latency_ms": 320})
```

Rename: `update_current_observation` → `update_current_span`. Replace `metadata=` with `properties=`.

### `propagate_attributes`

```python
# Before
from langfuse import propagate_attributes
with propagate_attributes(user_id="u_42", session_id="conv_99", tags=["beta"], metadata={"x": 1}):
    ...

# After
with bento.propagate_attributes(user_id="u_42", session_id="conv_99", tags=["beta"]):
    # metadata= dropped. Use properties= on individual track_ai calls instead.
    ...
```

Drop the `metadata=` kwarg; it's not supported on `propagate_attributes`. Move per-task metadata to `properties=` on the relevant `track_ai` calls.

### `langfuse.score` and `langfuse.get_prompt`

**Delete these.** No direct equivalents.

- `score()` values: move to `properties={"score_<name>": value}` on the relevant `track_ai` call. Bento's dashboard surfaces numeric properties as filter axes.
- `get_prompt()`: prompt management isn't part of Bento. Keep the source of truth elsewhere (a vault, a config file, your own DB).

### `langfuse.flush()` and `langfuse.shutdown()`

Rename: `bento.flush()`, `bento.shutdown()`. Same semantics.

## The single biggest gotcha

**`track_ai` uses `convo_id=`. Everywhere else uses `session_id=`.** Langfuse used `session_id` everywhere. In Bento, only `track_ai` takes `convo_id=`. `bento.init`, `bento.begin`, `bento.update_current_trace`, `bento.propagate_attributes` all take `session_id=`.

This trips up every Langfuse migrator. If a `track_ai` call site renders without a session column, check the kwarg name first.

## Other pitfalls

- **Forgetting `provider=` on `track_ai`.** Langfuse's drop-ins set provider from the SDK module they wrapped. Bento does not. Pass `provider=` explicitly.
- **Leaving the `from langfuse.openai import OpenAI` import in place.** After installing `openinference-instrumentation-openai`, swap to the stock `from openai import OpenAI`. The instrumentor wraps the stock client.
- **`metadata=` doesn't exist on `propagate_attributes`.** Use `properties=` on the per-call kwargs instead.
- **`as_type="generation"` doesn't have a direct decorator equivalent.** Replace the body with an explicit `bento.track_ai` call.
- **Uninstalling Langfuse before verify passes.** Both can coexist; spans go to different backends. Keep both during the port.
