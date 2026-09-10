#!/usr/bin/env bash
# OpenCode onboarding forwarder (invokes install.sh).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$DIR/install.sh" "$@"
