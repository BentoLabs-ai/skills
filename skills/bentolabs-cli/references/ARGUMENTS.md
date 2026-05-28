# How arguments map

Generated commands take three kinds of input. The rules are uniform across every group.

## Path params

Path params become required positional arguments, in the same order as the API path. They are always passed as strings.

For example, `GET /signals/{signal_id}` becomes:

```
bentolabs signals get <signal-id>
```

## The `workspace_id` exception

`workspace_id` is never a positional argument. The CLI fills it in from `--workspace <id>` or the saved default (set with `bentolabs workspaces use <id>`).

If no workspace is set, the CLI prints a hint pointing at `bentolabs workspaces list` and `bentolabs workspaces use <id>`.

## Query params

Each query param becomes a `--flag`. Types come from the API spec: string, int, float, bool, or list. Required and optional flags are honored. Default values from the spec are applied.

For list-valued flags, repeat the flag:

```
bentolabs traces list --tag prod --tag errors
```

For boolean flags, pass `--flag` or `--no-flag`. For int / float / string flags, pass `--flag <value>`.

## Request body

Three sources, in priority order:

1. `--data '<json>'` (inline)
2. `--data-file <path>` (from a file)
3. stdin (when stdin is piped in)

`raw` does not read stdin, only `--data` / `--data-file`.

## Shared flags

These flags work on every generated command:

| Flag | What it does |
|---|---|
| `--workspace <id>` | Use this workspace instead of the saved default. Only on commands that need one. |
| `--data '<json>'` | Send a JSON request body inline. |
| `--data-file <path>` | Send a JSON request body from a file. |
| `--output <mode>` | `pretty` (default), `raw`, or `table`. See `references/OUTPUT-MODES.md`. |
| `--help` | Show the command's signature and exit. |
