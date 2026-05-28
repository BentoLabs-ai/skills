---
name: bentolabs-migrate
description: Use when migrating an existing AI observability or analytics SDK to Bento. Triggers include "migrate from Raindrop", "migrate from Langfuse", "replace raindrop-ai", "replace langfuse", "port `raindrop.track_ai` to bento", "convert `@observe` to bento", "we already have Raindrop installed", "we already have Langfuse installed", existing usage of `raindrop.analytics`, `raindrop.identify`, `raindrop.track_signal`, `@observe`, `from langfuse.openai`, `from langfuse.langchain`, `langfuse.score`, or `langfuse.get_prompt`. Covers the three migration paths (Path A `bento.instrument()` for ADK, Path B OpenInference instrumentors for auto-captured LLM calls, Path C manual per-call translation), the `convo_id` vs `session_id` kwarg footgun, `provider=` now required (Bento does not auto-infer), the OpenInference instrumentor setup, and the safe coexistence window where both SDKs run side by side until verification passes. Do NOT use for greenfield integration; use `bentolabs-integrate` instead.
metadata:
  version: "1.0"
---

# Bento migration

Use this skill when an existing AI observability or analytics SDK is already installed and the user wants to move to Bento. The two supported source SDKs today are **Raindrop** (`raindrop-ai`, `import raindrop.analytics`) and **Langfuse** (Python SDK v3, `from langfuse`, `@observe`).

If the project has no existing tracing SDK, use `bentolabs-integrate` instead.

## Migration workflow

Copy this checklist into the response and check items off:

```
Bento migration progress:
- [ ] Step 1: Detect. Confirm which SDK is in use (Raindrop or Langfuse) and where it's wired in.
- [ ] Step 2: Install Bento. Add bentolabs-sdk alongside the existing SDK. Do NOT uninstall yet.
- [ ] Step 3: Pick the path. A (ADK present), B (auto-capture via OpenInference), C (manual translation). Most projects use a mix of B and C.
- [ ] Step 4: Port the code. Walk references/RAINDROP.md or references/LANGFUSE.md for the source-specific translation.
- [ ] Step 5: Verify. Run scripts/verify.py and confirm one row appears in the Bento dashboard. Only THEN uninstall the old SDK.
```

The old SDK stays installed during the port. Removing it before verify creates a window where neither tool is recording. Keep both, ship the diff, verify, then uninstall.

## Step 1: Detect the source SDK

Run `scripts/detect.sh` from the repo root. It greps for Raindrop and Langfuse imports, decorators, and the package names in `pyproject.toml` / `requirements*.txt`.

The output tells you:

- Which SDK is in use (Raindrop, Langfuse, or both).
- Which auto-capture or drop-in patterns are present (`auto_instrument=True`, `langfuse.openai`, `langfuse.langchain`, `@observe`, etc.).
- Which call sites need manual translation.

Summarize the findings to the user before editing. Confirm migrate vs fresh-integration-alongside is what they want; some users intentionally run two SDKs in parallel for A/B comparison.

## Step 2: Install Bento

Run `scripts/install-bento.sh`. It picks the package manager (uv, poetry, pdm, or pip), installs `bentolabs-sdk` (with the `[adk]` extra if you set `ADK_PRESENT=1`), and adds a `BENTOLABS_API_KEY` placeholder to `.env`.

Keys come from `https://platform.bentolabs.ai`. Prefix `bl_pk_`. The SDK validates the key up front and raises `BentoAuthError("invalid_api_key_format")` on a bad value before any network I/O.

**Do not uninstall the source SDK yet.** Both can coexist; their spans land in different backends.

## Step 3: Pick the migration path

The three paths apply in order. Fall through to the next on a miss. Most projects end up using **Path B** for the bulk of the auto-captured LLM calls plus **Path C** for the handful of bespoke decorators or spans.

| Path | When it applies | What changes |
|---|---|---|
| **A — `bento.instrument()`** | App uses Google ADK. | Three lines at startup. No per-call code. |
| **B — OpenInference instrumentor** | App used Raindrop's `auto_instrument` OR Langfuse's `langfuse.openai` / `langfuse.langchain` drop-ins. | Install the matching `openinference-instrumentation-<openai\|anthropic\|bedrock\|langchain>` and register it with a `BentoLabsSpanProcessor`. Call sites stay untouched. |
| **C — manual translation** | Everything else (custom decorators, bespoke spans, `raindrop.track_ai`, `@observe(as_type="generation")`, etc.). | Per-call-site rename. See `references/RAINDROP.md` or `references/LANGFUSE.md`. |

Read `references/PATHS.md` for the per-path setup snippets (Path A startup, Path B `BentoLabsSpanProcessor` wiring, Path C entry points). Run `scripts/install-instrumentors.sh` to install the OpenInference instrumentors for the LLM SDKs you found in Step 1.

## Step 4: Port the code

Pick the per-SDK translation guide that matches what Step 1 found:

- **Raindrop**: read `references/RAINDROP.md`. Replaces `import raindrop.analytics as raindrop` with `import bentolabs_sdk as bento`. Translates `raindrop.init`, `raindrop.track_ai`, `raindrop.identify`, `raindrop.track_signal`, `@raindrop.task`.
- **Langfuse**: read `references/LANGFUSE.md`. Replaces `Langfuse(...)` / `get_client()` with `bento.init`. Translates `@observe`, `propagate_attributes`, `update_current_trace`, `update_current_observation`, `langfuse.score`, `langfuse.get_prompt`.

Both guides flag the biggest footgun in Bento: **`track_ai` uses `convo_id=`. Everywhere else uses `session_id=`.** Same value, different kwarg name.

## Step 5: Verify and uninstall

Run `scripts/verify.py`. It sends one `hello_world` event, flushes, and a row should appear in the dashboard within seconds.

For every real call site you ported in Step 4, run the user flow once and confirm one row appears with all six fields populated: `provider`, `model`, `input`, `output`, `user_id`, `convo_id`. If any column is empty, return to Step 4 for that site.

Only after every column is filled, uninstall the source SDK:

- **Raindrop**: `pip uninstall raindrop-ai`. Remove `RAINDROP_*` env vars.
- **Langfuse**: `pip uninstall langfuse`. Remove `LANGFUSE_*` env vars.

## Gotchas

Concrete corrections the agent will get wrong without being told.

- **Do NOT uninstall the source SDK before verify passes.** The window between uninstall and successful Bento verification is a gap where nothing records. Keep both during the port.
- **`track_ai` uses `convo_id=`, everywhere else uses `session_id=`.** The single biggest footgun, especially when porting from Langfuse where everything is `session_id`. `bento.init`, `bento.begin`, `bento.update_current_trace`, `bento.propagate_attributes` all take `session_id=`; only `track_ai` takes `convo_id=`. Same value, different kwarg name.
- **`provider=` is now required and not auto-inferred from the model name.** Raindrop's `auto_instrument=True` and Langfuse's drop-ins guessed provider from the SDK module they wrapped. Bento does not. Pass `provider="openai"` / `"anthropic"` / `"aws_bedrock"` / `"google"` explicitly on every `track_ai` call.
- **A Bedrock model id like `anthropic.claude-3-sonnet-20240229-v1:0` needs `provider="aws_bedrock"`, NOT `"anthropic"`.** Common gotcha if the migrator was relying on Langfuse's inference.
- **Langfuse drop-in clients must be replaced with stock clients.** After installing `openinference-instrumentation-openai` and registering it with `BentoLabsSpanProcessor`, replace `from langfuse.openai import OpenAI` with stock `from openai import OpenAI`. The instrumentor wraps the stock client.
- **Raindrop's `auto_instrument=True` covered OpenAI / Anthropic / Bedrock via Traceloop.** Preserve that auto-capture by registering the matching OpenInference instrumentor; don't try to wrap every call site by hand.
- **Drop `langfuse.score(...)`, `langfuse.get_prompt(...)`, and dataset calls.** No direct equivalents. Move score values to `properties={"score_<name>": value}` on `track_ai`. Prompt management isn't part of Bento; keep the source-of-truth elsewhere.
- **`@raindrop.task` and `@bento.tool` differ in scope.** Raindrop collapsed task and tool into one decorator. Bento uses `@bento.tool` for everything tool-shaped. `@bento.interaction` is for top-level handlers; `@bento.tool` is for helpers.
- **Both SDKs emitting spans for the same call site is fine, but expect duplicates in your old tool while migrating.** They write to different backends; Bento ignores Raindrop / Langfuse spans and vice versa.

## Reference

For the per-path setup snippets (Path A ADK, Path B OpenInference instrumentors, Path C manual entry points), read `references/PATHS.md`.

For the Raindrop translation guide, read `references/RAINDROP.md`.

For the Langfuse translation guide, read `references/LANGFUSE.md`.

For diagnostics when traces don't appear or columns are empty, read `references/TROUBLESHOOTING.md`.

Deeper docs live at `https://docs.bentolabs.ai/migrations/raindrop.md` and `https://docs.bentolabs.ai/migrations/langfuse.md`.

## Related

- For a greenfield install with no existing SDK, use `bentolabs-integrate`.
- For driving the platform from a terminal after the migration, use `bentolabs-cli`.
