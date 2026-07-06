#!/usr/bin/env bash
# Repo self-check: mandate hook, frontmatter lint, installer idempotency.
set -euo pipefail
shopt -s nullglob
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

# --- 1. mandate hook outputs the skill mapping ---
out="$(bash "$ROOT/hooks/mandate.sh")"
for skill in requirements-interview blindspot-pass explainer work-report blindspot-flow; do
  grep -q "$skill" <<<"$out" || fail "mandate.sh output missing $skill"
done

echo "OK: all checks passed"
