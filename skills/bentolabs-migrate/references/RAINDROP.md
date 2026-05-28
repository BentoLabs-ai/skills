# Migrating from Raindrop (`raindrop-ai`)

For `import raindrop.analytics` users. Full translation table is at `https://docs.bentolabs.ai/migrations/raindrop.md`.

## Step order

1. `pip install bentolabs-sdk`. Do not uninstall `raindrop-ai` yet.
2. **Path A first.** If Google ADK is in use, add `bento.init(...)` + `bento.instrument()` at startup. See `references/PATHS.md` Path A.
3. **Path B next.** Raindrop's `auto_instrument=True` covered OpenAI / Anthropic / Bedrock via Traceloop. Preserve that auto-capture by installing the matching OpenInference instrumentors and wiring them to a `BentoLabsSpanProcessor`. See `references/PATHS.md` Path B.
4. **Path C for the rest.** Walk the renames below for every remaining call site.
5. Run `scripts/verify.py`. Confirm the row lands. THEN `pip uninstall raindrop-ai`.

## Per-call rename

### Import and init

```python
# Before
import raindrop.analytics as raindrop
raindrop.init(write_key="rd_...")     # or api_key=

# After
import bentolabs_sdk as bento
bento.init(api_key="bl_pk_...")        # or set BENTOLABS_API_KEY env var
```

The write key / api key prefix changes from `rd_` to `bl_pk_`. The env var is `BENTOLABS_API_KEY`.

### `raindrop.track_ai`

The most common call. Same kwarg names, EXCEPT you must now pass `provider=` explicitly.

```python
# Before
raindrop.track_ai(
    event="chat_completion",
    user_id="user_42",
    convo_id="conv_abc",
    model="gpt-4o",
    input=messages,
    output=reply,
)

# After
bento.track_ai(
    event="chat_completion",
    user_id="user_42",
    convo_id="conv_abc",
    model="gpt-4o",
    provider="openai",        # ← required. Bento does not auto-infer from model name.
    input=messages,
    output=reply,
)
```

For a Bedrock model id like `anthropic.claude-3-sonnet-20240229-v1:0`, pass `provider="aws_bedrock"` (not `"anthropic"`).

### `raindrop.identify` and `raindrop.track_signal`

**Delete these calls.** Bento doesn't have equivalents.

Move user traits to either:
- `properties=` on each `track_ai` call: `properties={"plan": "pro", "is_premium": True}`.
- `tags=` registered once at `bento.init(...)` for static traits across all spans.

Move `track_signal` payloads to `properties=` on the relevant `track_ai` call. If you were using signals as evaluation feedback, Bento's dashboard surfaces evaluations from spans directly; the standalone signal model isn't ported.

### `@raindrop.task` and `@raindrop.tool`

Raindrop collapsed task and tool into one decorator. In Bento, use `@bento.tool` for both:

```python
# Before
@raindrop.task
def web_search(query: str) -> list[str]: ...

# After
import bentolabs_sdk as bento

@bento.tool
def web_search(query: str) -> list[str]: ...
```

`@bento.interaction` is for top-level handlers; `@bento.tool` is for helpers. Migrating a top-level `@raindrop.task` decorator that wraps a request handler is often clearer as `@bento.interaction`.

### `raindrop.begin(...)` trajectories

Same shape; rename the import.

```python
# Before
with raindrop.begin(event="user_turn", convo_id=convo_id) as interaction: ...

# After
with bento.begin(event="user_turn", convo_id=convo_id) as interaction: ...
```

`bento.begin` takes `session_id=`, but it also accepts `convo_id=` as an alias for back-compat across the SDK. If the original code passed `convo_id`, leaving it works; new code prefers `session_id` on `begin`.

### `raindrop.flush()` and `raindrop.shutdown()`

Same names: `bento.flush()`, `bento.shutdown()`. Same semantics.

## Common pitfalls

- **Forgetting `provider=`.** Raindrop's `auto_instrument` set provider from the LLM SDK module. Bento does not, even after migration. Pass it explicitly.
- **`convo_id` vs `session_id` mixup.** Raindrop used `convo_id` everywhere. Bento uses `session_id` on `init`, `begin`, `update_current_trace`, `propagate_attributes`; only `track_ai` keeps `convo_id`. Same value, different kwarg name.
- **Uninstalling Raindrop too early.** Both can coexist during the port. Spans land in different backends; nothing breaks.
