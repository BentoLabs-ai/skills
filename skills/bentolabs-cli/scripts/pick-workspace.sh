#!/usr/bin/env bash
# Pick a default workspace.
#
# CLI commands act on one workspace at a time. After running this once,
# you can drop --workspace from later commands. Override per command with
# `--workspace <id>` if you need to target a different workspace.

set -euo pipefail

bentolabs workspaces list

read -r -p "Workspace ID to set as default: " WS_ID
bentolabs workspaces use "$WS_ID"
