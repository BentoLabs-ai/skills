# Troubleshooting

Failure modes you'll hit with `bentolabs-cli`, and the fix for each.

## "no workspace selected"

No default workspace is set. Either save one or pass it for the single command:

```bash
bentolabs workspaces list
bentolabs workspaces use <ws-id>     # saves the default
# or, one-off:
bentolabs traces list --workspace <ws-id>
```

`workspace_id` is never a positional argument. It always comes from `--workspace` or the
saved default.

## "Not signed in" or a 401

Your token refresh failed — usually because another process rotated the refresh token
first. The CLI clears its local tokens **on purpose** when this happens, so the next call
returns a clean 401 instead of a confusing partial-auth state. Just sign in again:

```bash
bentolabs auth login      # or: scripts/sign-in.sh
bentolabs auth whoami     # confirm
```

## "no such command" / a command is missing from `--help`

Your cached command list is stale and predates a new API endpoint. Re-pull it:

```bash
bentolabs refresh
```

The CLI auto-pulls the list the first time you run a non-built-in command, so a fresh
install already has commands. `refresh` is for picking up endpoints added *after* your
cache was built. If you maintain `commands.yaml`, regenerate it too:

```bash
python3 scripts/generate-commands-yaml.py
```

## `--output` value rejected

Only `pretty` and `raw` are valid on generated commands; the default is
`pretty`. (On `bentolabs raw`, an unknown `--output` is quietly ignored rather than
rejected — still, stick to these two.)

## A piped body was silently dropped

You piped JSON into `bentolabs raw`. `raw` does **not** read stdin — the body was
discarded with no error. Pass it explicitly:

```bash
bentolabs raw POST /workspaces/<ws-id>/issues --data '{"title":"..."}'
# or
bentolabs raw POST /workspaces/<ws-id>/issues --data-file ./body.json
```

(Generated commands *do* read stdin when it isn't a terminal; `raw` is the one exception.)

## `config set` rejects a key

`config set` accepts only `api-base`:

```bash
bentolabs config set api-base https://api.example.com   # local dev / custom deploy
```

Anything else raises `BadParameter`. Two things you might expect to set here live
elsewhere: tokens are written by `auth login`, and the default workspace by
`workspaces use` — never by `config set`. The config file is created `0600`.

## A positional argument is misread

You probably passed `workspace_id` (or another `ws`-injected value) positionally. On
generated commands the positionals are *only* the non-workspace path params, in path
order. Check the exact order with `bentolabs <group> <command> --help`.

## Quick triage

```bash
bentolabs auth whoami        # signed in? which workspace?
bentolabs config show        # api-base, workspace_id, config path
bentolabs version            # installed version
bentolabs refresh            # stale command list
```
