# Output modes

Switch with `--output <mode>`. Default is `pretty`.

| Mode | Use |
|---|---|
| `pretty` | Default. Human-readable JSON with syntax highlighting. |
| `raw` | Plain JSON to stdout. For pipes into `jq`, `grep`, files. |
| `table` | Renders a table for list endpoints. Falls back to pretty when the shape isn't tabular. |

## Table mode envelope unwrap

Most Bento list endpoints return:

```json
{
  "items": [ ... ],
  "next_cursor": "..."
}
```

Table mode unwraps `items` automatically. You don't have to pass `--output raw | jq '.items[]'` first. If the value is already a top-level list of objects, table mode renders that directly. For non-tabular shapes (single objects, strings), it falls back to pretty.

## Piping with `raw`

```
bentolabs traces list --output raw | jq -r '.items[].id' | head -20
```

`raw` writes one trailing newline. Strings are written verbatim; everything else is JSON-encoded with `default=str` for non-serializable values.

## 204 No Content

`pretty`, `raw`, and `table` all print nothing for a 204 response. Exit code is still zero.
