# Troubleshooting

When the verify script doesn't land a row, or ported call sites render with empty columns, walk this list.

## Verify script silent

1. **`BENTOLABS_API_KEY` not in the running process.** Setting it in `~/.zshrc` doesn't help if the IDE or CI launched from a different env. Verify with `os.environ.get("BENTOLABS_API_KEY")`. Must start with `bl_pk_`.
2. **Old SDK still capturing the spans.** If both Raindrop or Langfuse and Bento are wired in parallel, the OTel context could be routing spans elsewhere. Run the verify script in isolation (no other SDK init in the same process).
3. **Daemon worker not alive.** Add `import threading; print([t.name for t in threading.enumerate()])` after `bento.init()`. The thread list should include `OtelBatchSpanRecordProcessor`.
4. **`flush()` not called.** `verify.py` calls it; if you wrote a custom verify, add `bento.flush()` before exit.

## Ported call site renders, but columns are empty

- **`provider` empty.** Bento does NOT auto-infer provider from the model name. Pass `provider="openai"` / `"anthropic"` / `"aws_bedrock"` etc. explicitly on every `track_ai` call.
- **`convo_id` empty on `track_ai`.** You passed `session_id=` instead of `convo_id=`. The kwarg name only differs on `track_ai`; everywhere else (`init`, `begin`, `update_current_trace`, `propagate_attributes`) uses `session_id`. This is the single biggest Langfuse-migration footgun.
- **`user_id` empty.** Either the per-call kwarg wasn't threaded through, or the init-time getter returned `None`. Add a `print(...)` inside the getter to confirm it's firing at the right time.
- **`model` empty.** Pass `model=` explicitly. For Path B (OpenInference instrumentors), the instrumentor sets `gen_ai.request.model` automatically from the LLM SDK call; check that the call goes through the instrumented client.
- **Bedrock model grouped under `anthropic`.** Pass `provider="aws_bedrock"`, not `"anthropic"`. The model id is intentionally ambiguous.
- **A `property` shows as a string when an int was passed.** Only happens for dicts and mixed-type lists. Flatten or pre-serialize. Primitives and homogeneous lists keep their type.

## Path B instrumentor not capturing

- **Instrumentor not installed.** Run `scripts/install-instrumentors.sh <sdk>` for each LLM SDK in use.
- **Instrumentor registered against a different TracerProvider than the one Bento wraps.** Use one provider, register `BentoLabsSpanProcessor` on it, then call `Instrumentor().instrument(tracer_provider=provider)` on the same one.
- **Still importing the Langfuse drop-in.** After Path B setup, replace `from langfuse.openai import OpenAI` with stock `from openai import OpenAI`. The instrumentor wraps the stock client.

## Two SDKs running, traces in both backends

This is expected during the port. Both SDKs emit spans for the same call site, and each ships to its own backend. Bento ignores Raindrop / Langfuse spans and vice versa. After Step 5 verify passes, uninstall the source SDK to stop the duplicate emission.

## Refresh token rotated, Bento returns 401

If `bento.init()` once worked but now `flush()` returns 401, the API key may have been rotated in the dashboard. Pull the new key from `https://platform.bentolabs.ai`, update `BENTOLABS_API_KEY`, and re-run.
