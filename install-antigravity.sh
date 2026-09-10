#!/usr/bin/env bash
# Antigravity-side onboarding (forwarder to install.sh for backwards compatibility).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$DIR/install.sh" "$@"
