---
name: bentolabs-integrate
description: Use when integrating Bento into a Python app, wiring the Google ADK integration (`bento.instrument()`), manually tracking LLM calls with `bento.track_ai`, registering identity getters at `bento.init`, grouping multi-step agent flows with `bento.begin` trajectories, mapping OpenTelemetry GenAI / OpenInference semantic conventions to Bento dashboard columns, debugging missing traces or empty dashboard columns, or migrating from Raindrop or Langfuse. Covers Python SDK install, the `bl_pk_` API key, the four must-pass arguments to `track_ai` (`user_id`, `convo_id`, `model`, `provider`), input/output capture, properties type fidelity, the `flush()` / `shutdown()` lifecycle, and the lower-level OTel transport for apps with an existing TracerProvider.
metadata:
  version: "2.0"
---

# Bento

Bento is production infrastructure for AI agents. The Python SDK emits OpenTelemetry spans with `gen_ai.*` and `openinference.*` semantic conventions. The dashboard turns those spans into traces, signals (English-language failure-mode detectors), alerts, evaluations, and versioned improvements. The TypeScript SDK is in active development and not yet generally available.

Two paths, picked per call site:

- **Integration** (`bento.instrument()`). One line. Captures every model call, tool call, and agent step from **Google ADK**. Default path when ADK is present.
- **Manual tracking** (`bento.track_ai`). One call per LLM site. Default path for everything else (OpenAI, Anthropic, Bedrock, Vertex, etc.).

The two compose. Manual `track_ai` and tool spans inside a `bento.begin(...)` block share `trace_id` with any spans the integration captures.

## Integration workflow

Copy this checklist into the response and check items off while integrating:

```
Bento integration progress:
- [ ] Step 1: Discover. Map the codebase (language, framework, LLM SDK, OTel, env config). Whether ADK is in use changes Step 3.
- [ ] Step 2: Install. Add bentolabs-sdk (plus the [adk] extra if applicable) and set BENTOLABS_API_KEY.
- [ ] Step 3: Wire it up. Either bento.instrument() once at startup (ADK) OR wrap each LLM call site with bento.track_ai (everything else). Often both.
- [ ] Step 4: Identify. Register user_id / session_id getters at bento.init(), or thread them through to each call site.
- [ ] Step 5: Verify. Run the verify snippet, confirm the trace lands in the dashboard.
```

Walk these in order. Do not skip Step 1; the discovery output drives every later decision.

## Step 1: Discover the codebase

Run `scripts/discover.sh` from the repo root. It runs grouped grep and `find` commands covering language and Python version, web framework, LLM call sites, Google ADK usage, existing OpenTelemetry setup, env file location, and competing SDKs (Raindrop, Langfuse).

Read each section's output. The output drives:

- **Step 3 path choice.** ADK present means Path A; otherwise Path B.
- **Where the API key goes.** Section 1f shows the env file.
- **Whether to migrate or run alongside.** Section 1g flags Raindrop or Langfuse usage.

If a Python project isn't detected (no `pyproject.toml` / `setup.py` / `requirements.txt`, no `*.py` files), stop. Point the user at `https://docs.bentolabs.ai/typescript` and explain that the TS SDK is not yet GA.

### Existing competing SDK

If section 1g finds Raindrop or Langfuse usage, **ask the user before proceeding**:

> I found existing **`<Raindrop|Langfuse>`** usage at `<file:line>` (and N more sites). Do you want me to:
>
> 1. **Migrate** the existing code from `<Raindrop|Langfuse>` to Bento (port every call site, then remove the old SDK)
> 2. **Fresh integration**. Keep `<Raindrop|Langfuse>` in place and add Bento alongside it (for A/B testing or instrumenting only new code)
>
> Which one?

If they pick migrate, read `references/MIGRATIONS.md` and follow the per-SDK guide. Both SDKs can coexist during the port; only uninstall the old one after Step 5 verify passes.

If they pick fresh integration, continue with the greenfield Step 3 patterns. Note in your summary that the project also runs `<Raindrop|Langfuse>` so the reviewer knows two SDKs will emit spans.

Never silently pick one path.

### Summarize before continuing

Write a short summary back to the user with: language and Python version, framework, **whether ADK is in use**, the list of LLM call sites with file:line and provider, whether OTel is already wired, where env vars live, **whether Raindrop or Langfuse is present and which path the user picked**. Confirm before editing.

## Step 2: Install and authenticate

Run `scripts/install.sh`. It picks the package manager (uv, poetry, pdm, or pip), installs `bentolabs-sdk` (with the `[adk]` extra if you set `ADK_PRESENT=1`), and adds a `BENTOLABS_API_KEY` placeholder to `.env`.

Keys come from `https://platform.bentolabs.ai`. The prefix is `bl_pk_` and the SDK validates it up front. A bad key raises `BentoAuthError("invalid_api_key_format")` before any network I/O.

`bento.init()` is optional in the pure `track_ai` flow. The first call lazy-initializes from `BENTOLABS_API_KEY` and `BENTOLABS_BASE_URL` (defaults to `https://api.bentolabs.ai`). For an integration, call `bento.init()` explicitly at startup so identity getters are registered before the first captured span.

## Step 3: Instrument

Pick the path that matches what Step 1d found.

- **Path A — integration.** ADK in use. Three lines at startup, zero per-call-site code. Read `references/PATH-A-ADK.md`.
- **Path B — manual `track_ai`.** Everything else, or any uncovered SDK in a project that also uses ADK. One call per LLM site. Read `references/PATH-B-MANUAL.md`.

The two paths compose. Open a `bento.begin(...)` trajectory and any spans the integration captures inside it share `trace_id` with your manual `track_ai` and `tool_span` calls.

## Step 4: Source `user_id` and `convo_id`

These two identifiers unlock the dashboard's user filter and conversation timeline. Read `references/IDENTITY.md`. Pick one of two patterns and apply consistently:

- **Pattern 1: init-time getters.** Preferred for Path A; also works for Path B.
- **Pattern 2: per-call kwargs.** Path B only.

Late-binding identity (`bento.update_current_trace` and `bento.propagate_attributes`) is covered in the same reference.

## Step 5: Verify

Run the smoke test that matches the Step 3 path you took.

- **Manual path**: `scripts/verify-manual.py`. Sends a `hello_world` event, flushes, and a row should appear in the dashboard within seconds.
- **Integration path**: `scripts/verify-integration.py`. Prints `activated: 'adk'` on success. Then invoke one real ADK agent run and confirm a span lands.

To confirm the SDK's background worker is alive, run `scripts/check-worker.py`. The thread list should include `OtelBatchSpanRecordProcessor`. If it doesn't, `init()` failed silently or SDK calls are happening before init resolved; re-check Step 2.

### Validation loop

For every real call site instrumented in Step 3, run the user flow once and confirm one row appears with: correct `provider`, correct `model`, non-empty `input` and `output`, `user_id` populated, `convo_id` populated. If any column is empty, return to Step 3 for that call site. Do not move on until every column is filled.

If `user_id` or `convo_id` is empty on integration-captured spans, the init-time getter returned `None`. See `references/TROUBLESHOOTING.md`.

## Reference

For deep reference (public surface, the four kwargs that must be on every call, trajectories, properties, lifecycle, the lower-level OTel transport for apps with an existing `TracerProvider`), read `references/REFERENCE.md`.

For migrations from Raindrop or Langfuse, read `references/MIGRATIONS.md`.

For diagnostics when traces don't appear or columns are empty, read `references/TROUBLESHOOTING.md`.

For deeper docs hosted at `docs.bentolabs.ai` as plain Markdown, see the URL list in `references/DOCS-INDEX.md`.

## TypeScript

The TypeScript SDK is in active development and not yet generally available. Do not generate Node or browser instrumentation code from this skill. Point users at `https://docs.bentolabs.ai/typescript` for status.
