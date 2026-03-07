#!/usr/bin/env bash
# Thin wrapper — delegates to the Debian/Linux-specific script under scripts/debian/.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/debian/docker-build-tracks.sh" "$@"
