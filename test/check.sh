#!/usr/bin/env bash
# Repo self-check: mandate hook, frontmatter lint, reference integrity, installer idempotency.
set -euo pipefail
shopt -s nullglob
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

# --- 1. mandate hook outputs the skill mapping ---
out="$(bash "$ROOT/hooks/mandate.sh")"
for skill in requirements-interview blindspot-pass explainer work-report blindspot-flow; do
  grep -q "$skill" <<<"$out" || fail "mandate.sh output missing $skill"
done

# --- 2. frontmatter lint (skills + agents) ---
files=("$ROOT"/skills/*/SKILL.md "$ROOT"/agents/*.md)
[[ ${#files[@]} -eq 10 ]] || fail "expected 10 lintable files (5 skills + 5 agents), got ${#files[@]}"
for f in "${files[@]}"; do
  [[ "$(head -n1 "$f")" == "---" ]] || fail "$f: missing frontmatter open"
  fm="$(awk '/^---$/{c++; next} c==1' "$f")"
  grep -q '^name:' <<<"$fm" || fail "$f: missing name"
  grep -q '^description:' <<<"$fm" || fail "$f: missing description"
done

# --- 3. skill → agent reference integrity (agent rename tripwire) ---
refs="$(grep -ho '`TypeName: [a-z-]*`' "$ROOT"/skills/*/SKILL.md | sed 's/.*`TypeName: \([a-z-]*\)`.*/\1/' | sort -u)" || true
[[ -n "$refs" ]] || fail "no TypeName references found in any SKILL.md — pattern drift?"
while read -r name; do
  [[ -f "$ROOT/agents/$name.md" ]] || fail "skills reference agent '$name' but agents/$name.md is missing"
done <<<"$refs"

# --- 4. readability standard present in its 4 self-contained copies (see ANTIGRAVITY.md conventions) ---
n="$(grep -l '25 어절' "$ROOT"/skills/*/SKILL.md | wc -l)" || true
[[ "$n" -eq 4 ]] || fail "readability standard marker ('25 어절') in $n SKILL.md files, expected 4"

# --- 5. install.sh idempotency (fake consumer project) ---
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/proj/.antigravity/shared"
cp -a "$ROOT/." "$tmp/proj/.antigravity/shared/"
(
  cd "$tmp/proj"
  bash .antigravity/shared/install.sh >/dev/null
  cp .antigravity/settings.json ../settings.first
  bash .antigravity/shared/install.sh >/dev/null   # second run must change nothing
  cmp -s .antigravity/settings.json ../settings.first || { echo "settings.json rewritten on second run"; exit 1; }
  [[ -e .antigravity/skills/blindspot-pass ]] || { echo "skill symlink missing"; exit 1; }
  [[ -f .antigravity/skills/blindspot-pass/SKILL.md ]] || { echo "skill symlink broken"; exit 1; }
  [[ -e .antigravity/agents/codebase-scanner.md ]] || { echo "agent symlink missing"; exit 1; }
  [[ -f .antigravity/agents/codebase-scanner.md ]] || { echo "agent symlink broken"; exit 1; }
  [[ "$(grep -c 'mandate.sh' .antigravity/settings.json)" == 1 ]] || { echo "hook missing or duplicated"; exit 1; }
  [[ "$(grep -cxF '@.antigravity/shared/MANDATE.md' ANTIGRAVITY.md)" == 1 ]] || { echo "ANTIGRAVITY.md import missing or duplicated"; exit 1; }
) || fail "install idempotency check failed"

# --- 6. countable readability limits: checker runs clean on the shipped templates ---
if command -v python3 >/dev/null 2>&1 && python3 -c "" >/dev/null 2>&1; then
  PY_CMD=python3
elif command -v python >/dev/null 2>&1 && python -c "" >/dev/null 2>&1; then
  PY_CMD=python
else
  fail "neither python3 nor python found"
fi

$PY_CMD "$ROOT/skills/work-report/scripts/quiz_check.py" \
  "$ROOT/skills/work-report/templates/quiz.html" \
  "$ROOT/skills/work-report/templates/report.md" >/dev/null \
  || fail "quiz_check.py reported violations on the work-report templates"

echo "OK: all checks passed"
