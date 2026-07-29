#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
[[ -f "$ROOT/AGENTS.md" ]] || fail "AGENTS.md missing"
[[ ! -e "$ROOT/CLAUDE.md" ]] || fail "CLAUDE.md remains active"

subjects=("$ROOT/README.md" "$ROOT/AGENTS.md" "$ROOT/MANDATE.md" "$ROOT/install.sh" "$ROOT/hooks/mandate.sh")
subjects+=("$ROOT"/skills/*/SKILL.md "$ROOT"/agents/*.toml)
forbidden='\.claude/|CLAUDE\.md|CLAUDE_PROJECT_DIR|Claude Code|AskUserQuestion|Skill tool|Agent calls|subagent_type|model: (haiku|sonnet)|/blindspot-flow'
if rg -n "$forbidden" "${subjects[@]}"; then fail "retired runtime language remains"; fi

for required in '.codex/shared' '.agents/skills' '.codex/agents' '.codex/hooks.json' 'AGENTS.md' '$blindspot-flow' '/hooks'; do
  rg -q -F "$required" "$ROOT/README.md" || fail "README missing $required"
done
echo "OK: active Codex documentation"
