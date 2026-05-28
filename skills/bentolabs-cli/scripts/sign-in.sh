#!/usr/bin/env bash
# Sign in to Bento from the CLI.
#
# Opens the browser to a Bento Allow / Deny page. Tokens land in the OS
# keychain (macOS Keychain, Linux Secret Service, Windows Credential
# Locker). On headless Linux without secret-service, the CLI falls back
# to a chmod 0600 file. Tokens refresh automatically near expiry.

set -euo pipefail

bentolabs auth login

bentolabs auth whoami
