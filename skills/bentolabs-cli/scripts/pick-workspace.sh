#!/usr/bin/env bash
#
# WHAT THIS DOES
#   Lets you choose a default workspace. The CLI works on one workspace
#   at a time, so picking a default here means you don't have to type
#   --workspace on every later command.
#
# HOW IT WORKS
#   It lists your workspaces, asks you to type the ID of the one you want,
#   and saves it as the default. To target a different workspace later
#   for a single command, just add --workspace <id> to that command.

# Stop immediately if any command fails, so problems are obvious.
set -euo pipefail

# 1. Show the workspaces you can choose from.
bentolabs workspaces list

# 2. Ask which one to make the default, and save it.
read -r -p "Workspace ID to set as default: " WS_ID
bentolabs workspaces use "$WS_ID"
