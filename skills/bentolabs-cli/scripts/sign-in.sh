#!/usr/bin/env bash
#
# WHAT THIS DOES
#   Signs you in to Bento from the command line, then prints who you are
#   to confirm it worked.
#
# WHAT TO EXPECT
#   It opens your browser to a Bento "Allow / Deny" page. Approve it, and
#   the CLI stores your login tokens in the operating system's keychain
#   (macOS Keychain, Linux Secret Service, or Windows Credential Locker).
#   On a headless Linux box with no secret service, it falls back to a
#   private file (chmod 0600). Tokens refresh themselves near expiry, so
#   you normally only sign in once per machine.

# Stop immediately if any command fails, so problems are obvious.
set -euo pipefail

# Open the browser and complete the login.
bentolabs auth login

# Confirm we're signed in by printing the current user.
bentolabs auth whoami
