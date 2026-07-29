#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
[[ -f "$ROOT/AGENTS.md" ]] || fail "AGENTS.md missing"
[[ ! -e "$ROOT/CLAUDE.md" ]] || fail "CLAUDE.md remains active"

subjects=("$ROOT/README.md" "$ROOT/AGENTS.md" "$ROOT/MANDATE.md" "$ROOT/install.sh" "$ROOT/hooks/mandate.sh")
subjects+=("$ROOT"/skills/*/SKILL.md "$ROOT"/agents/*.toml)
subjects+=("$ROOT"/skills/*/templates/*)
forbidden='\.claude/|CLAUDE\.md|CLAUDE_PROJECT_DIR|Claude Code|AskUserQuestion|Skill tool|Agent calls|subagent_type|model: (haiku|sonnet)|/blindspot-flow|change-analyzer|check-runner|codebase-scanner|doc-verifier|domain-researcher'
if rg -n "$forbidden" "${subjects[@]}"; then fail "retired runtime language remains"; fi

for required in '.codex/shared' '.agents/skills' '.codex/agents' '.codex/hooks.json' 'AGENTS.md' '$blindspot-flow' '/hooks'; do
  rg -q -F "$required" "$ROOT/README.md" || fail "README missing $required"
done

if rg -q '^질문은 .*한 번에 하나씩' "$ROOT/README.md"; then
  fail "README applies the requirements-interview turn rule globally"
fi
rg -q -F '`requirements-interview`는 한 번에 한 질문씩 제시한다.' "$ROOT/README.md" || fail "README missing requirements-interview turn scope"
rg -q -F '`blindspot-pass`는 구조 영향이 큰 순서로 최대 일곱 개의 결정을 묶어 제시할 수 있다.' "$ROOT/README.md" || fail "README missing blindspot-pass batch scope"

runtime_limits="$(sed -n '/^### 실행 환경의 제한이 있을 때$/,/^### 산출물 위치$/p' "$ROOT/README.md")"
for required in \
  '거부된 역할은 대기 상태로 유지한다.' \
  '자리가 나면 재시도한다.' \
  '일찍 종합하거나 역할을 빠뜨리지 않는다.' \
  '전체 `developer_instructions`와 같은 작업 입력으로 부모가 직접 수행한다.'
do
  rg -q -F "$required" <<<"$runtime_limits" || fail "README missing thread-cap behavior: $required"
done
echo "OK: active Codex documentation"
