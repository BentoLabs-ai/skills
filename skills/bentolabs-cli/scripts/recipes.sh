#!/usr/bin/env bash
#
# WHAT THIS IS
#   A grab-bag of common Bento CLI commands. This is a reference, NOT a
#   script to run top-to-bottom. Copy the one block you need and run it
#   on its own. Each block stands alone.

# Stop immediately if any command fails, so problems are obvious.
set -euo pipefail

# Show the 5 most recent traces as a readable table.
bentolabs traces list --limit 5

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
# must fill in the workspace_id yourself in the path (no /v1 prefix).
bentolabs raw GET /health
# bentolabs raw GET /workspaces/<ws-id>/traces
# bentolabs raw POST /workspaces/<ws-id>/issues --data '{"title":"..."}'

# More ways to find the right command:
#   bentolabs --help                      # list groups
#   bentolabs <group> --help              # commands in a group
#   bentolabs <group> <command> --help    # one command's exact arguments
# The bundled ../commands.yaml is a routing map of every group/command.

# Aggregate views (analytics group needs --start and --end):
# bentolabs analytics trace-summary --start 2026-05-01 --end 2026-05-29

# Inspect one analyzed run and its findings (trajectories group).
# NOTE: boolean flags are --flag / --no-flag, never --flag true.
# bentolabs trajectories list --has-errors
# bentolabs trajectories list --is-suspicious
# bentolabs trajectories list-findings <trajectory-id>

# Workspace is a QUERY flag (--workspace-id) on these, not the injected --workspace:
# bentolabs incidents list --workspace-id <ws-id>
