---
name: bentolabs-cli
description: Use when working with `bentolabs-cli`, the command-line client for Bento. Triggers include listing traces, signals, or analytics from a terminal, scripting Bento data into `jq` / `grep` pipelines, automating workflows in CI, hitting any Bento REST endpoint with `bentolabs raw`, signing in with `bentolabs auth login`, picking a default workspace with `bentolabs workspaces use`, refreshing the command list with `bentolabs refresh`, choosing between `pretty` / `raw` / `table` output, debugging "no workspace selected" or `--workspace` errors, and bootstrapping the CLI on a new machine (uv tool install or pip). Covers install, browser-based sign-in with keychain token storage, how path params map to positionals (and the `workspace_id` exception), how query params map to `--flags`, body input from `--data` / `--data-file` / stdin, and the six built-in commands (`auth`, `workspaces use`, `raw`, `refresh`, `config`, `version`).
metadata:
  version: "1.0"
---

# bentolabs-cli

`bentolabs-cli` is the command-line client for [Bento](https://docs.bentolabs.ai). It builds its command tree from the Bento API, so every dashboard surface (traces, signals, analytics, clusters, drift, trajectories) is reachable from your terminal.

Use this skill when the user wants to drive Bento from a terminal, script it into a pipeline, or hit an arbitrary endpoint.

## Install

```bash
uv tool install bentolabs-cli      # recommended
# or
python3 -m pip install --user bentolabs-cli

bentolabs version                  # confirm install
```

Requires Python 3.10 or higher.

## Sign in

```bash
bentolabs auth login
```

Opens the browser to a Bento Allow / Deny page. Tokens land in the OS keychain (macOS Keychain, Linux Secret Service, Windows Credential Locker), with a `chmod 0600` file fallback on headless Linux. Tokens refresh automatically near expiry.

```bash
bentolabs auth whoami      # see signed-in identity
bentolabs auth logout      # revoke and clear
```

The CLI authenticates as a user, not a workspace API key. Anything the user can do in the dashboard, the CLI can do.

## Pick a default workspace

Every command runs against one workspace. Set the default once:

```bash
bentolabs workspaces list
bentolabs workspaces use <ws-id>
```

Override per command with `--workspace <id>`. The flag wins over the default.

If the user gets "no workspace selected", run `workspaces list` then `workspaces use <id>`.

## How arguments map

The command tree is generated from the API spec. Three rules:

| Source | Mapping |
|---|---|
| Path param like `/things/{thing_id}` | Required positional argument, in path order. |
| `workspace_id` in the path | Never a positional. Resolved from `--workspace` or the saved default. |
| Query params | Keyword `--flags`. Types inferred from the spec. Repeat the flag for list values. |
| Request body | `--data '<json>'`, `--data-file <path>`, or piped from stdin. |

```bash
bentolabs traces list --limit 5
bentolabs traces list --tag prod --tag errors
bentolabs signals get <signal-id>
bentolabs <group> <create> --data '{"name":"prod"}'
cat payload.json | bentolabs <group> <create>
```

## Output modes

Pretty JSON is the default. Switch with `--output`:

| Mode | Use |
|---|---|
| `pretty` | Default. Human-readable JSON with syntax highlighting. |
| `raw` | Plain JSON to stdout. For pipes. |
| `table` | Renders a table for list endpoints. Unwraps `{"items": [...]}` envelopes automatically. Falls back to pretty for non-tabular shapes. |

```bash
bentolabs traces list --output table
bentolabs traces list --output raw | jq -r '.items[].id'
```

## Built-in commands

Six commands are hand-written rather than generated from the API:

- **`auth login` / `auth whoami` / `auth logout`** — Browser sign-in. Tokens in the keychain. Auto-refresh.
- **`workspaces use <id>`** — Save the default workspace. Pairs with `workspaces list`.
- **`raw <METHOD> <PATH>`** — Send an ad-hoc request. Honors `--data`, `--data-file`, `--output`, but not stdin. Fill in path params (including `workspace_id`) yourself.
- **`refresh`** — Re-pull the command list from the API. Run when a new endpoint is missing from `--help`.
- **`config show`** — Print the active configuration and the path to the config file. The config file is `0600`.
- **`version`** — Print the installed CLI version.

```bash
bentolabs raw GET /health
bentolabs raw GET /v1/workspaces/<ws-id>/traces
bentolabs raw POST /v1/workspaces/<ws-id>/things --data '{"x":1}'
bentolabs refresh
bentolabs config show
```

## Common recipes

List the 5 most recent traces in the default workspace:

```bash
bentolabs traces list --limit 5 --output table
```

Pipe trace IDs into another command:

```bash
bentolabs traces list --output raw \
  | jq -r '.items[].id' \
  | head -20
```

Hit a brand-new endpoint that isn't in the cached command tree yet:

```bash
bentolabs refresh
bentolabs <new-group> --help
```

Send a request that the generated tree doesn't cover:

```bash
bentolabs raw GET /v1/workspaces/<ws-id>/new-endpoint
```

## Troubleshooting

**"no workspace selected"** — Run `bentolabs workspaces list`, then `bentolabs workspaces use <id>`. Or pass `--workspace <id>` per command.

**"Not signed in" / 401** — Token refresh may have failed (another process rotated the refresh token). Run `bentolabs auth login` again.

**Command not found** — Run `bentolabs refresh` to pull the latest command tree. New endpoints from API ships aren't visible until refresh.

**Header `--output mode` unknown** — Only `pretty`, `raw`, and `table` are valid for generated commands. Default is `pretty`.

## Related

For SDK install, instrumentation, and dashboard integration, use the `bentolabs-integrate` skill instead. The CLI is for talking to the platform from a terminal; the SDK is for emitting traces from application code.

Docs: [docs.bentolabs.ai/cli/installation](https://docs.bentolabs.ai/cli/installation) and [docs.bentolabs.ai/cli/commands](https://docs.bentolabs.ai/cli/commands).
