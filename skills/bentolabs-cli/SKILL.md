---
name: bentolabs-cli
description: Use when working with `bentolabs-cli`, the command-line client for Bento. Triggers include listing traces, signals, or analytics from a terminal, scripting Bento data into `jq` or `grep` pipelines, automating workflows in CI, hitting any Bento REST endpoint with `bentolabs raw`, signing in with `bentolabs auth login`, picking a default workspace with `bentolabs workspaces use`, refreshing the command list with `bentolabs refresh`, choosing between `pretty` / `raw` / `table` output, debugging "no workspace selected" or `--workspace` errors, and bootstrapping the CLI on a new machine.
metadata:
  version: "2.0"
---

# bentolabs-cli

`bentolabs-cli` is the command-line client for [Bento](https://docs.bentolabs.ai). It builds its command tree from the Bento API, so every dashboard surface (traces, signals, analytics, clusters, drift, trajectories) is reachable from the terminal.

Use this skill when the user wants to drive Bento from a terminal, script it into a pipeline, or hit an arbitrary endpoint.

## Setup, once per machine

Run these in order. Each is a small wrapper script in this skill.

1. **Install** the CLI: `scripts/install.sh`. Requires Python 3.10 or higher. Confirms the install with `bentolabs version`.
2. **Sign in** with `scripts/sign-in.sh`. Opens the browser. Tokens land in the OS keychain and refresh automatically.
3. **Pick a default workspace** with `scripts/pick-workspace.sh`. After this, drop `--workspace` from later commands. Pass `--workspace <id>` to override.

The CLI authenticates as a user, not a workspace API key. Anything the user can do in the dashboard, the CLI can do.

## Running commands

The command tree is generated from the API. To explore:

- `bentolabs --help` lists all groups.
- `bentolabs <group> --help` lists commands inside one group.
- `bentolabs <group> <command> --help` shows the signature.

If a command is missing from `--help`, run `bentolabs refresh` to pull the latest tree from the API.

For how arguments map (path params, the `workspace_id` exception, query params, body), read `references/ARGUMENTS.md`.

For the six hand-written built-in commands (`auth`, `workspaces use`, `raw`, `refresh`, `config`, `version`) and what they do, read `references/COMMANDS.md`.

For output modes (`pretty`, `raw`, `table`) and the envelope unwrap, read `references/OUTPUT-MODES.md`.

For copy-paste recipes (5 most recent traces, jq pipe, raw request), read `scripts/recipes.sh`.

## When to reach for `raw`

If the generated command tree doesn't expose an endpoint cleanly, or you need full control over the request, use `bentolabs raw <METHOD> <PATH>`. Fill in path params (including `workspace_id`) yourself. `raw` reads its body from `--data` or `--data-file` only, not from stdin. See `references/COMMANDS.md` for the full signature.

## Troubleshooting

**"no workspace selected"** — Run `scripts/pick-workspace.sh` again, or pass `--workspace <id>` per command.

**"Not signed in" or 401** — Token refresh may have failed because another process rotated the refresh token first. Run `scripts/sign-in.sh` again.

**Command not found** — Run `bentolabs refresh` to pull the latest tree. New API endpoints aren't visible until refresh.

**Unknown `--output` mode** — Only `pretty`, `raw`, and `table` are valid on generated commands. Default is `pretty`.

## Related

For SDK install, instrumentation, and dashboard integration, use the `bentolabs-integrate` skill. The CLI is for talking to the platform from a terminal; the SDK is for emitting traces from application code.

Docs: [docs.bentolabs.ai/cli/installation](https://docs.bentolabs.ai/cli/installation) and [docs.bentolabs.ai/cli/commands](https://docs.bentolabs.ai/cli/commands).
