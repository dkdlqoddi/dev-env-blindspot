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
refs="$(grep -ho 'subagent_type: `[a-z-]*`' "$ROOT"/skills/*/SKILL.md | sed 's/.*`\([a-z-]*\)`.*/\1/' | sort -u)" || true
[[ -n "$refs" ]] || fail "no subagent_type references found in any SKILL.md — pattern drift?"
while read -r name; do
  [[ -f "$ROOT/agents/$name.md" ]] || fail "skills reference agent '$name' but agents/$name.md is missing"
done <<<"$refs"

# --- 4. readability standard present in its 4 self-contained copies (see CLAUDE.md conventions) ---
n="$(grep -l '25 어절' "$ROOT"/skills/*/SKILL.md | wc -l)" || true
[[ "$n" -eq 4 ]] || fail "readability standard marker ('25 어절') in $n SKILL.md files, expected 4"

# --- 5. install.sh idempotency (fake consumer project) ---
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/proj/.claude/shared"
cp -a "$ROOT/." "$tmp/proj/.claude/shared/"
(
  cd "$tmp/proj"
  bash .claude/shared/install.sh >/dev/null
  cp .claude/settings.json ../settings.first
  bash .claude/shared/install.sh >/dev/null   # second run must change nothing
  cmp -s .claude/settings.json ../settings.first || { echo "settings.json rewritten on second run"; exit 1; }
  [[ -L .claude/skills/blindspot-pass ]] || { echo "skill symlink missing"; exit 1; }
  [[ -f .claude/skills/blindspot-pass/SKILL.md ]] || { echo "skill symlink broken"; exit 1; }
  [[ -L .claude/agents/codebase-scanner.md ]] || { echo "agent symlink missing"; exit 1; }
  [[ -f .claude/agents/codebase-scanner.md ]] || { echo "agent symlink broken"; exit 1; }
  [[ "$(grep -c 'mandate.sh' .claude/settings.json)" == 1 ]] || { echo "hook missing or duplicated"; exit 1; }
  [[ "$(grep -cxF '@.claude/shared/MANDATE.md' CLAUDE.md)" == 1 ]] || { echo "CLAUDE.md import missing or duplicated"; exit 1; }
) || fail "install idempotency check failed"

echo "OK: all checks passed"
