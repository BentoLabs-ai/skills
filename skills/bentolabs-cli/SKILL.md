---
name: bentolabs-cli
description: Use when working with `bentolabs-cli`, the command-line client for Bento. Triggers include listing traces, signals, or analytics from a terminal, scripting Bento data into `jq` or `grep` pipelines, automating workflows in CI, hitting any Bento REST endpoint with `bentolabs raw`, signing in with `bentolabs auth login`, picking a default workspace with `bentolabs workspaces use`, refreshing the command list with `bentolabs refresh`, choosing between `pretty` / `raw` / `table` output, debugging "no workspace selected" or `--workspace` errors, and bootstrapping the CLI on a new machine.
metadata:
  version: "2.1"
---

# bentolabs-cli

`bentolabs-cli` is the command-line client for [Bento](https://docs.bentolabs.ai). Use this skill when someone wants to drive Bento from a terminal, pipe its data into a script, or hit an API endpoint directly.

The thing to understand first: the CLI builds its list of commands from the Bento API itself. That means every surface you see in the dashboard — traces, signals, analytics, clusters, drift, trajectories — has a matching command. It also means the command list can go stale, which is why there's a `refresh` command (more on that below).

## Setting it up (do this once per machine)

Run these three steps in order. Each one is a small wrapper script in this skill.

1. **Install the CLI.** Run `scripts/install.sh`. You need Python 3.10 or newer. When it finishes it prints the version, which confirms the install worked.
2. **Sign in.** Run `scripts/sign-in.sh`. It opens your browser to approve the login, then stores your tokens in the operating system's keychain. The tokens refresh themselves, so you normally only do this once.
3. **Pick a default workspace.** Run `scripts/pick-workspace.sh`. After this you can leave `--workspace` off your commands. If you ever need to target a different workspace for one command, add `--workspace <id>` to it.

One important detail: the CLI signs in as *you*, the user — not as a workspace API key. So anything you can do in the dashboard, the CLI can do too.

## Running commands

Because the command list comes from the API, the way to explore it is `--help` at each level:

- `bentolabs --help` lists all the command groups.
- `bentolabs <group> --help` lists the commands inside one group.
- `bentolabs <group> <command> --help` shows what arguments a command takes.

If a command you expect is missing from `--help`, the local command list is probably stale. Run `bentolabs refresh` to pull the latest one from the API, then try again.

For the deeper details, read these references when you need them:

- How arguments map to a command (path params, the special `workspace_id` case, query params, request body): `references/ARGUMENTS.md`.
- The six hand-written built-in commands (`auth`, `workspaces use`, `raw`, `refresh`, `config`, `version`) and exactly what each does: `references/COMMANDS.md`.
- The output modes (`pretty`, `raw`, `table`) and how the response envelope is unwrapped: `references/OUTPUT-MODES.md`.
- Copy-paste examples (recent traces, a `jq` pipe, a raw request): `scripts/recipes.sh`.

## When to use `bentolabs raw`

Most of the time a generated command will fit. But if the command list doesn't expose an endpoint cleanly, or you need full control over the request, use `bentolabs raw <METHOD> <PATH>`. With `raw` you fill in the path parameters yourself, including `workspace_id`. Note that `raw` reads its request body only from `--data` or `--data-file` — it does not read from stdin. The full signature is in `references/COMMANDS.md`.

## Things that are easy to get wrong

- **`workspace_id` is never a positional argument on a generated command.** It comes from `--workspace <id>`, or from the default you saved with `bentolabs workspaces use`. If you try to pass it positionally, the command misreads its arguments.
- **`bentolabs raw` ignores stdin.** If you pipe a body into it, the body is silently dropped. Always pass the body with `--data '<json>'` or `--data-file <path>`. (Generated commands *do* read stdin when it isn't a terminal; `raw` is the one exception.)
- **A token-refresh failure clears the keychain on purpose.** If another process rotated the refresh token before this one did, the CLI clears its local tokens and your next command returns 401. That's intentional — just run `scripts/sign-in.sh` again.

## Troubleshooting

- **"no workspace selected"** — You haven't set a default workspace. Run `scripts/pick-workspace.sh`, or add `--workspace <id>` to the command.
- **"Not signed in", or a 401** — Your token refresh probably failed because another process rotated the token first. Run `scripts/sign-in.sh` again.
- **"no such command"** — Your local command list is stale. Run `bentolabs refresh` to pull the latest one. New API endpoints aren't visible until you do.
- **An `--output` value is rejected** — Only `pretty`, `raw`, and `table` are valid on generated commands. The default is `pretty`. (On `bentolabs raw`, an unknown `--output` value is quietly ignored rather than rejected, so stick to the three valid modes.)

## Related skills

- To install the SDK and send traces from your application code, use `bentolabs-integrate`.
- To move an existing Raindrop or Langfuse setup over to Bento, use `bentolabs-migrate`.

The CLI is for talking to the platform from a terminal; the SDK skills are for emitting traces from application code.

Docs: [docs.bentolabs.ai/cli/installation](https://docs.bentolabs.ai/cli/installation) and [docs.bentolabs.ai/cli/commands](https://docs.bentolabs.ai/cli/commands).
