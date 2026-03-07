#!/usr/bin/env bash
# Wrapper: run the 1.40.8 release build script.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/debian/build-release-1408.sh" "$@"
