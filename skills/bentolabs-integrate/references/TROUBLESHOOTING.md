# Troubleshooting

When `track_ai` calls don't show up in the dashboard, walk this list top to bottom. The fix is almost always one of these five.

## Spans never arrive

1. **`flush()` missing before exit.** Short scripts, notebooks, Lambdas, and `os._exit` all drop the last batch. Add `bento.flush()`.
2. **`BENTOLABS_API_KEY` not in the running process.** Setting it in `~/.zshrc` doesn't help if the IDE or CI launched from a different env. Verify inside the process with `os.environ.get("BENTOLABS_API_KEY")`. Must start with `bl_pk_`.
3. **`BENTOLABS_BASE_URL` pointing at the wrong host.** Check with `from bentolabs_sdk import resolve_options; print(resolve_options().base_url)`.
4. **Daemon worker not alive.** Run `scripts/check-worker.py`. The thread list should include `OtelBatchSpanRecordProcessor`.
5. **Queue full.** Past 2048 queued spans the SDK drops the oldest and logs a WARNING. Enable `logging.basicConfig(level=logging.WARNING)`.

## Fields look wrong

- `provider` column empty: pass `provider=` explicitly on every call.
- Conversations appear as N separate rows: the same `convo_id` is not being passed on every turn.
- User filter does nothing: `user_id` is missing, or was passed inside `properties=`. Use the top-level kwarg.
- Bedrock model is grouped under `anthropic`: pass `provider="aws_bedrock"`.
- Property shows as a string when an int was passed: this only happens for dicts or mixed-type lists. Flatten or pre-serialize.

## Integration-captured spans missing identity

If `user_id` or `convo_id` is empty on integration-captured ADK spans, the init-time getter (Pattern 1 in `IDENTITY.md`) returned `None`. Either the `ContextVar` wasn't set before the LLM call (middleware ordering bug) or the getter swallowed an exception. Add `print(...)` inside the getter to confirm it's firing at the right time.

## `bento.instrument()` returned `None`

The `[adk]` extra isn't installed in the venv this script is using. Run `pip install "bentolabs-sdk[adk]"` and confirm with `pip show bentolabs-sdk` that the package landed.

## A second integration claim is being ignored

If another component already wrapped ADK directly (for example, `GoogleADKInstrumentor().instrument(...)`), `bento.instrument("adk")` logs a warning and returns `None`. Either remove the host-side wiring or skip Bento's integration claim.
