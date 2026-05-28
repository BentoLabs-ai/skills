# Built-in commands

Six commands are hand-written rather than generated from the API. Everything else is built from the OpenAPI spec and shows up under `bentolabs <group> --help`.

## `auth`

Sign in, sign out, and check who you are.

| Command | Effect |
|---|---|
| `bentolabs auth login` | Opens the browser to a Bento Allow / Deny page. Stores tokens in the OS keychain. |
| `bentolabs auth whoami` | Prints signed-in email and the current default workspace. |
| `bentolabs auth logout` | Revokes the session on the server and clears local tokens. |

Tokens refresh automatically near expiry. If the refresh fails because another process rotated the refresh token first, the next command returns 401 and asks for a fresh `bentolabs auth login`.

## `workspaces use`

Save a default workspace ID. Pairs with `bentolabs workspaces list`.

| Command | Effect |
|---|---|
| `bentolabs workspaces list` | Lists workspaces you belong to. |
| `bentolabs workspaces use <ws-id>` | Saves the workspace as the default. |

Pass `--workspace <id>` on any command to override the saved default for that one invocation. The flag wins.

## `raw`

Send an ad-hoc request to any Bento API path.

```
bentolabs raw <METHOD> <PATH> [--data '<json>'] [--data-file <path>] [--output <mode>]
```

- `<METHOD>` is `GET`, `POST`, `PUT`, `PATCH`, or `DELETE`.
- `<PATH>` is the API path. You fill in path params (including `workspace_id`) yourself.
- `raw` does not read stdin. Use `--data` or `--data-file` to send a body.

## `refresh`

Re-pull the command list from the API. Run this when a new endpoint is missing from `--help`. Prints how many operations were cached.

## `config show`

Print the active CLI configuration and the path to the config file on disk. Tokens are written by `auth login`. The default workspace is written by `workspaces use`. The config file is created with `0600` permissions.

## `version`

Print the installed CLI version.
