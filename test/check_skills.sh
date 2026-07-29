#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

expected=(blindspot-flow blindspot-pass explainer requirements-interview work-report)
files=("$ROOT"/skills/*/SKILL.md)
[[ ${#files[@]} -eq 5 ]] || fail "expected 5 skills, got ${#files[@]}"
for name in "${expected[@]}"; do
  file="$ROOT/skills/$name/SKILL.md"
  [[ -f "$file" ]] || fail "missing $file"
  rg -q "^name: $name$" "$file" || fail "$file: name mismatch"
  rg -q '^description: .*Use when ' "$file" || fail "$file: missing trigger description"
  rg -q '^## Gotchas$' "$file" || fail "$file: missing Gotchas"
done

forbidden='AskUserQuestion|subagent_type|Agent calls|Skill tool|\.claude/skills|/blindspot-flow'
if rg -n "$forbidden" "$ROOT"/skills/*/SKILL.md; then
  fail "Claude-only skill instruction remains"
fi

refs="$(rg -o 'custom agent `(change_analyzer|check_runner|codebase_scanner|doc_verifier|domain_researcher)`' "$ROOT"/skills/*/SKILL.md | sed 's/.*`\([^`]*\)`.*/\1/' | sort -u)"
for name in change_analyzer check_runner codebase_scanner doc_verifier domain_researcher; do
  rg -qx "$name" <<<"$refs" || fail "no skill references custom agent $name"
  [[ -f "$ROOT/agents/$name.toml" ]] || fail "missing referenced agent $name"
done

echo "OK: skill host contract"
