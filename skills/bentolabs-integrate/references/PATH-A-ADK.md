# Step 3 Path A: Google ADK integration

Used when Step 1d found Google ADK. Replaces most per-call-site wrapping with a three-line install at app startup.

## A1. One-time setup at app startup

```python
import bentolabs_sdk as bento

bento.init(
    user_id=lambda: get_current_user_id(),        # see references/IDENTITY.md
    session_id=lambda: get_current_session_id(),
)
bento.instrument()                                 # auto-detects ADK
```

`bento.instrument()` returns `"adk"` when activated, or `None` when the `[adk]` extra is not installed. To pin the pick explicitly, call `bento.instrument("adk")`. Unknown names raise `ValueError`. A missing extra logs a warning and returns `None` (it does NOT raise).

The call is idempotent. A second `bento.instrument()` with the same target is a no-op.

## A2. Where to put it

Wherever the app initializes itself, once, at the boundary, before any LLM call:

- **FastAPI** — module-level call before `app = FastAPI()`, or in a `lifespan` startup handler.
- **Django** — `apps.py:ready()` or `wsgi.py` / `asgi.py`.
- **Flask** — module-level, before `create_app()`.
- **Worker / CLI** — top of the entry-point module, before any task runs.

Do not call `bento.init` or `bento.instrument` per request. They are idempotent, but a partial `init()` per request would churn identity registration.

## A3. What you get for free

Every span the integration captures (ADK agent runs, ADK tool calls, and the LLM calls ADK makes) lands in the dashboard with:

- `gen_ai.user.id` from your `user_id` getter
- `gen_ai.conversation.id` from your `session_id` getter
- `gen_ai.request.model` and `gen_ai.system` from the framework
- `input.value` and `output.value` from the prompt and completion
- `openinference.span.kind` set so tool spans get the right icon

No code changes anywhere else. Validate with Step 5.

## A4. Mixing the integration with `track_ai`

If the same project also calls OpenAI / Anthropic / Bedrock directly (Step 1c found matches outside ADK), wrap those sites with `track_ai` (Path B). Inside a `bento.begin(...)` trajectory, integration-captured spans and manual `track_ai` calls share one `trace_id`.

```python
with bento.begin(event="user_turn", convo_id=conv_id) as i:
    # ADK agent run, captured by the integration
    result = await runner.run(query)

    # Direct OpenAI call, needs track_ai
    raw = openai_client.embeddings.create(
        model="text-embedding-3-small", input=text
    )
    bento.track_ai(
        event="embed",
        model="text-embedding-3-small",
        provider="openai",
        input=text,
        output=str(raw.data[0].embedding[:5]) + "...",
    )
```

## A5. Reverse / shutdown

```python
bento.uninstrument()        # remove every active integration
bento.uninstrument("adk")   # specific one
bento.shutdown()            # calls uninstrument() automatically
```

`shutdown()` is what you want for credential rotation and test isolation. After `shutdown()`, a subsequent `bento.init()` re-creates a fresh provider, so you must re-call `bento.instrument()` to re-attach.

## A6. When Bento can't claim the library

If another component already instrumented ADK (for example, the host app called `GoogleADKInstrumentor().instrument(...)` directly), `bento.instrument("adk")` logs a warning and returns `None`. The existing wrappers stay intact. Either remove the host-side wiring, or skip `bento.instrument(...)` and live with the spans landing in the host's pipeline only.
