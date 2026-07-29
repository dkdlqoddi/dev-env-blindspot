#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

expected=(blindspot-flow blindspot-pass explainer requirements-interview work-report)
support_assets=(
  requirements-interview/templates/requirements.md
  blindspot-pass/templates/unknowns.md
  explainer/templates/explainer.md
  work-report/templates/implementation-notes.md
  work-report/templates/report.md
  work-report/templates/quiz.html
  work-report/scripts/quiz_check.py
)
files=("$ROOT"/skills/*/SKILL.md)
[[ ${#files[@]} -eq 5 ]] || fail "expected 5 skills, got ${#files[@]}"
for name in "${expected[@]}"; do
  file="$ROOT/skills/$name/SKILL.md"
  [[ -f "$file" ]] || fail "missing $file"
  rg -q "^name: $name$" "$file" || fail "$file: name mismatch"
  rg -q '^description: .*Use when ' "$file" || fail "$file: missing trigger description"
  rg -q '^## Gotchas$' "$file" || fail "$file: missing Gotchas"
done
for relative in "${support_assets[@]}"; do
  [[ -f "$ROOT/skills/$relative" ]] || fail "missing referenced skill support asset $relative"
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

assert_thread_cap_contract() {
  local section="$1" label="$2" required
  for required in \
    'Attempt to spawn every role, submitting as many pending roles in parallel as the runtime accepts.' \
    'Keep every rejected role pending.' \
    'Wait for a subagent slot to become available, then retry each pending role.' \
    'Never synthesize early or drop a role.' \
    "If subagent spawning remains unavailable, run every pending role in the parent using that role profile's complete \`developer_instructions\` and the same task input."
  do
    rg -q -F "$required" <<<"$section" || fail "$label: missing thread-cap contract: $required"
  done
}

blindspot_pass="$ROOT/skills/blindspot-pass/SKILL.md"
explainer="$ROOT/skills/explainer/SKILL.md"
work_report="$ROOT/skills/work-report/SKILL.md"
assert_thread_cap_contract \
  "$(sed -n '/^2\. \*\*Fan out scanners\.\*\*/,/^3\. \*\*Synthesize\.\*\*/p' "$blindspot_pass")" \
  "$blindspot_pass initial scan"
assert_thread_cap_contract \
  "$(sed -n '/^4\. \*\*Resolve with the user\.\*\*/,/^5\. \*\*Document\.\*\*/p' "$blindspot_pass")" \
  "$blindspot_pass follow-up scan"
assert_thread_cap_contract \
  "$(sed -n '/^4\. \*\*Verify\.\*\*/,/^5\. \*\*Hand off\.\*\*/p' "$explainer")" \
  "$explainer verification"
assert_thread_cap_contract \
  "$(sed -n '/^1\. \*\*Analyze\.\*\*/,/^2\. \*\*Merge sources\.\*\*/p' "$work_report")" \
  "$work_report analysis"

echo "OK: skill host contract"
