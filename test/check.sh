#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

bash "$ROOT/test/check_agents.sh"
bash "$ROOT/test/check_skills.sh"
bash "$ROOT/test/check_installer.sh"
bash "$ROOT/test/check_active.sh"

n="$(rg -l -F '25 어절' "$ROOT"/skills/*/SKILL.md | wc -l)" || true
[[ "$n" -eq 4 ]] || fail "readability standard marker ('25 어절') in $n SKILL.md files, expected 4"

python3 "$ROOT/skills/work-report/scripts/quiz_check.py" \
  "$ROOT/skills/work-report/templates/quiz.html" \
  "$ROOT/skills/work-report/templates/report.md" >/dev/null
if python3 "$ROOT/skills/work-report/scripts/quiz_check.py" \
  "$ROOT/test/fixtures/invalid-quiz.html" \
  "$ROOT/test/fixtures/invalid-report.md" >"$tmp/invalid.out" 2>&1; then
  fail "quiz_check.py accepted over-limit fixtures"
fi
for expected in '^[^:]+: 변경 요약:' '^[^:]+: Q1 question:' '^[^:]+: Q1 option has ' '^[^:]+: Q1 explain:' '^[^:]+: 요약:'; do
  rg -q "$expected" "$tmp/invalid.out" || fail "negative fixture missed $expected"
done

bash "$ROOT/test/check_codex.sh"
echo "OK: all checks passed"
