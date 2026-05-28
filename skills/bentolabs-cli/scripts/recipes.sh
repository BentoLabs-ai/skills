#!/usr/bin/env bash
#
# WHAT THIS IS
#   A grab-bag of common Bento CLI commands. This is a reference, NOT a
#   script to run top-to-bottom. Copy the one block you need and run it
#   on its own. Each block stands alone.

# Stop immediately if any command fails, so problems are obvious.
set -euo pipefail

# Show the 5 most recent traces as a readable table.
bentolabs traces list --limit 5 --output table

# Get raw JSON and pull just the trace IDs out of it with jq.
# (--output raw gives you the unformatted JSON to pipe around.)
bentolabs traces list --output raw \
  | jq -r '.items[].id' \
  | head -20

# Refresh the list of available commands from the API. Run this when a
# command you expect is missing from --help (new API endpoints don't show
# up until you refresh).
bentolabs refresh

# Call any API path directly when no built-in command fits. For "raw" you
# must fill in the workspace_id yourself in the path.
bentolabs raw GET /health
# bentolabs raw GET /v1/workspaces/<ws-id>/traces
# bentolabs raw POST /v1/workspaces/<ws-id>/things --data '{"x":1}'
