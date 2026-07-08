#!/usr/bin/env bash
# Repo self-check: mandate contents, frontmatter lint, plugin.json validity.
set -euo pipefail
shopt -s nullglob
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

# --- 1. mandate file contains the skill mapping ---
for skill in requirements-interview blindspot-pass explainer work-report blindspot-flow; do
  grep -q "$skill" "$ROOT/MANDATE.md" || fail "MANDATE.md missing $skill"
done

# --- 2. frontmatter lint (skills + agents) ---
files=("$ROOT"/skills/*/SKILL.md "$ROOT"/agents/*.md)
[[ ${#files[@]} -eq 9 ]] || fail "expected 9 lintable files (5 skills + 4 agents), got ${#files[@]}"
for f in "${files[@]}"; do
  [[ "$(head -n1 "$f" | tr -d '\r')" == "---" ]] || fail "$f: missing frontmatter open"
  fm="$(awk '/^---(\r)?$/{c++; next} c==1' "$f")"
  grep -q '^name:' <<<"$fm" || fail "$f: missing name"
  grep -q '^description:' <<<"$fm" || fail "$f: missing description"
done

# --- 3. plugin.json validity ---
if command -v jq >/dev/null 2>&1; then
  jq -e . "$ROOT/plugin.json" >/dev/null || fail "plugin.json is not valid JSON"
  [[ "$(jq -r .name "$ROOT/plugin.json")" != "null" ]] || fail "plugin.json missing name"
else
  # fallback check if jq is missing
  grep -q '"name":' "$ROOT/plugin.json" || fail "plugin.json missing name"
fi

echo "OK: all checks passed"
