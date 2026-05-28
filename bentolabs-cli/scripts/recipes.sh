#!/usr/bin/env bash
# Common bentolabs-cli recipes. Run individual sections, not the whole
# file. Each block is independent.

set -euo pipefail

# 5 most recent traces, rendered as a table.
bentolabs traces list --limit 5 --output table

# Pipe trace IDs through jq.
bentolabs traces list --output raw \
  | jq -r '.items[].id' \
  | head -20

# Pull the latest commands from the API (run when a new endpoint is
# missing from --help).
bentolabs refresh

# Hit any API path directly. Fill in workspace_id yourself for raw.
bentolabs raw GET /health
# bentolabs raw GET /v1/workspaces/<ws-id>/traces
# bentolabs raw POST /v1/workspaces/<ws-id>/things --data '{"x":1}'
