#!/usr/bin/env bash
# Repository contract: Codex discovery, lite workflow, installer safety/idempotency, and converted records.
set -euo pipefail
shopt -s nullglob

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

# --- 1. Codex-only repository layout; superpowers documents are retired ---
[[ -f "$ROOT/AGENTS.md" ]] || fail "missing AGENTS.md"
[[ ! -e "$ROOT/CLAUDE.md" ]] || fail "CLAUDE.md must not ship on the Codex branch"
[[ ! -e "$ROOT/docs/superpowers" ]] || fail "docs/superpowers must be removed"

# --- 2. mandate hook is exact and compact ---
cmp -s <(bash "$ROOT/hooks/mandate.sh") "$ROOT/MANDATE.md" || fail "mandate hook output differs from MANDATE.md"
for text in '# Blindspot Mandate' '$blindspot-pass' 'docs/decisions.md' 'codebase_scanner'; do
  grep -qF "$text" "$ROOT/MANDATE.md" || fail "MANDATE.md missing '$text'"
done
[[ "$(wc -l < "$ROOT/MANDATE.md")" -le 10 ]] || fail "MANDATE.md exceeds 10 lines"

# --- 3. exactly one skill and one Codex custom-agent profile ---
skills=("$ROOT"/skills/*/SKILL.md)
profiles=("$ROOT"/agents/*.toml)
legacy_agents=("$ROOT"/agents/*.md)
[[ ${#skills[@]} -eq 1 ]] || fail "expected 1 skill, got ${#skills[@]}"
[[ ${#profiles[@]} -eq 1 ]] || fail "expected 1 TOML agent, got ${#profiles[@]}"
[[ ${#legacy_agents[@]} -eq 0 ]] || fail "Markdown agent definitions must not ship"

skill="${skills[0]}"
profile="${profiles[0]}"
[[ "$(awk '/^---$/{n++; next} n==1 && /^name:/{sub(/^name:[[:space:]]*/, ""); print; exit}' "$skill")" == "blindspot-pass" ]] || fail "skill name mismatch"
grep -q '^description: Use ' "$skill" || fail "skill trigger description must begin with Use"
grep -qx 'name = "codebase_scanner"' "$profile" || fail "agent name mismatch"
grep -qx 'model = "gpt-5.6-terra"' "$profile" || fail "agent model mismatch"
grep -qx 'model_reasoning_effort = "medium"' "$profile" || fail "agent effort mismatch"
grep -qx 'sandbox_mode = "read-only"' "$profile" || fail "agent must be read-only"
grep -q '^developer_instructions = """' "$profile" || fail "agent instructions missing"

# --- 4. skill workflow keeps both scans, Codex fallbacks, and one three-question round ---
for text in 'integration-points' 'edge-cases' 'codebase_scanner' 'IN PARALLEL' 'request_user_input' 'at most 3' '.codex/agents/codebase_scanner.toml' 'general subagent' 'parent'; do
  grep -qF "$text" "$skill" || fail "skill contract missing '$text'"
done
! grep -qE 'AskUserQuestion|subagent_type|CLAUDE\.md|at most 4|2–4 concrete' "$skill" || fail "skill retains a non-Codex workflow term"

# --- 5. decision table contract remains append-only and six cells wide ---
HDR='| 날짜 | 영역 | 결정 | 근거 | 기각한 대안 | 결정 주체 |'
SEP='|---|---|---|---|---|---|'
tpl="$ROOT/skills/blindspot-pass/templates/decisions.md"
grep -qxF '# 결정 기록' "$tpl" || fail "decision template title mismatch"
grep -qxF "$HDR" "$tpl" || fail "decision template header mismatch"
grep -qxF "$SEP" "$tpl" || fail "decision template separator missing"
! grep -q '^| 20' "$tpl" || fail "decision template ships a decision row"
grep -qF 'templates/decisions.md' "$skill" || fail "skill does not name the decision template"
grep -qF '날짜 | 영역 | 결정 | 근거 | 기각한 대안 | 결정 주체' "$skill" || fail "skill row order differs from template"

dec="$ROOT/docs/decisions.md"
grep -qxF "$HDR" "$dec" || fail "repository decision header mismatch"
grep -qxF "$SEP" "$dec" || fail "repository decision separator missing"
bad="$(awk -v sep="$SEP" 'f && !/^[|] 20/ {print NR ": " $0} $0 == sep {f=1}' "$dec")"
[[ -z "$bad" ]] || fail "every decision line must start with '| 20':"$'\n'"$bad"
bad="$(awk -F'|' '/^[|] 20/ && NF != 8 {print NR ": " $0}' "$dec")"
[[ -z "$bad" ]] || fail "decision rows must have six cells:"$'\n'"$bad"

# --- 6. fake consumer: preserve unrelated data, migrate old full install, stay idempotent ---
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
proj="$tmp/proj"
mkdir -p "$proj/.codex/shared"
cp -a "$ROOT/." "$proj/.codex/shared/"
git -C "$proj" init -q
(
  cd "$proj"
  mkdir -p .agents/skills/own-skill .codex/agents vendor nested/path
  printf '%s\n' own > .agents/skills/own-skill/SKILL.md
  printf '%s\n' own > vendor/own-skill
  ln -s ../../vendor/own-skill .agents/skills/own-link
  ln -s ../../.codex/shared/skills/retired-full-skill .agents/skills/retired-full-skill
  printf '%s\n' 'name = "own_agent"' > .codex/agents/own_agent.toml
  printf '%s\n' 'name = "domain_researcher"' '# consumer changed this old reserved profile' > .codex/agents/domain_researcher.toml
  cat > .codex/agents/change_analyzer.toml <<'LEGACY'
name = "change_analyzer"
description = "Read-only git diff analyst used by work-report report mode to identify changes, risks, plan deviations, test coverage, and quiz candidates."
sandbox_mode = "read-only"
developer_instructions = """
You are a git change analyst. You receive a base ref; if none is given, use `git merge-base main HEAD`, fall back to `master`, then the first commit. You may also receive a plan document path.

Follow this procedure:
1. Run `git diff --stat <base>...HEAD` for the shape of the change.
2. Run `git diff <base>...HEAD` and `git log --oneline <base>..HEAD` for content.
3. Read changed files where the diff alone is unclear.
4. When a plan document path is given, read it and note where the diff deviates from it in scope, approach, or behavior.
5. Check whether tests covering the changed behavior exist by looking for test files that touch the changed modules.

Never create, edit, delete, stage, commit, switch branches, or perform external writes. Use shell only for read-only git and inspection commands. Cite `path:line` for every risk. Risk spots include suspected defects in the diff, such as logic errors and unhandled edge cases; mark those 의심 결함. Quiz candidates cover behavior and risk, never trivia.

Return Korean sections named 변경 요약, 파일별 핵심 변경, 위험 지점, 계획 대비 이탈 when a plan exists, 테스트, and 퀴즈 후보. 변경 요약 is 2–4 sentences. Include a 파일별 핵심 변경 table with 파일 and 핵심 변경. For every 위험 지점, write `path:line` and why it is risky. For 계획 대비 이탈, describe what differs from or is missing from the plan and cite `path:line`. Describe whether tests cover the changed behavior and where. Provide 4–6 퀴즈 후보; each asks a point a reviewer must understand and gives the answer's gist.
"""
LEGACY
  cat > .codex/hooks.json <<'JSON'
{
  "owner": "consumer",
  "hooks": {
    "SessionStart": [
      {"matcher": "resume", "hooks": [{"type": "command", "command": "consumer-session-hook"}]}
    ],
    "Stop": [{"hooks": [{"type": "command", "command": "consumer-stop-hook"}]}]
  }
}
JSON
  printf '# consumer agents\n\nkeep-agents\n' > AGENTS.md
  printf '# consumer override\n\nkeep-override\n' > AGENTS.override.md

  bash .codex/shared/install.sh >/dev/null
  cp .codex/hooks.json ../hooks.first
  cp AGENTS.md ../agents.first
  cp AGENTS.override.md ../override.first
  cp .codex/agents/codebase_scanner.toml ../profile.first
  find .agents/skills .codex/agents -maxdepth 1 -mindepth 1 -printf '%p -> %l\n' | sort > ../entries.first

  bash .codex/shared/install.sh >/dev/null
  cmp -s .codex/hooks.json ../hooks.first || { echo "hooks changed on second install"; exit 1; }
  cmp -s AGENTS.md ../agents.first || { echo "AGENTS.md changed on second install"; exit 1; }
  cmp -s AGENTS.override.md ../override.first || { echo "AGENTS.override.md changed on second install"; exit 1; }
  cmp -s .codex/agents/codebase_scanner.toml ../profile.first || { echo "agent profile changed on second install"; exit 1; }
  find .agents/skills .codex/agents -maxdepth 1 -mindepth 1 -printf '%p -> %l\n' | sort > ../entries.second
  cmp -s ../entries.first ../entries.second || { echo "managed entries changed on second install"; exit 1; }

  [[ -L .agents/skills/blindspot-pass && -f .agents/skills/blindspot-pass/SKILL.md ]] || { echo "blindspot skill link missing"; exit 1; }
  [[ "$(readlink .agents/skills/blindspot-pass)" == '../../.codex/shared/skills/blindspot-pass' ]] || { echo "blindspot skill target mismatch"; exit 1; }
  [[ -f .codex/agents/codebase_scanner.toml && ! -L .codex/agents/codebase_scanner.toml ]] || { echo "scanner profile must be a regular file"; exit 1; }
  [[ -f .agents/skills/own-skill/SKILL.md && -L .agents/skills/own-link && -f .codex/agents/own_agent.toml ]] || { echo "consumer-owned content changed"; exit 1; }
  [[ ! -L .agents/skills/retired-full-skill ]] || { echo "dangling shared skill was not pruned"; exit 1; }
  [[ ! -e .codex/agents/change_analyzer.toml ]] || { echo "byte-identical old profile was not pruned"; exit 1; }
  grep -qF 'consumer changed this old reserved profile' .codex/agents/domain_researcher.toml || { echo "modified old profile was removed"; exit 1; }
  [[ "$(grep -cF 'dev-env-blindspot:mandate:start' AGENTS.md)" == 1 ]] || { echo "AGENTS mandate block count mismatch"; exit 1; }
  [[ "$(grep -cF 'dev-env-blindspot:mandate:start' AGENTS.override.md)" == 1 ]] || { echo "override mandate block count mismatch"; exit 1; }
  grep -qF keep-agents AGENTS.md && grep -qF keep-override AGENTS.override.md || { echo "consumer guidance changed"; exit 1; }
  grep -qF '"owner": "consumer"' .codex/hooks.json || { echo "hook top-level field lost"; exit 1; }
  grep -qF consumer-session-hook .codex/hooks.json && grep -qF consumer-stop-hook .codex/hooks.json || { echo "consumer hook lost"; exit 1; }
  [[ "$(grep -cF 'mandate.sh' .codex/hooks.json)" == 1 ]] || { echo "blindspot hook missing or duplicated"; exit 1; }
  [[ ! -e docs ]] || { echo "installer created docs/"; exit 1; }
  (cd nested/path && bash "$(git rev-parse --show-toplevel)/.codex/shared/hooks/mandate.sh") > ../nested-mandate
  cmp -s ../nested-mandate .codex/shared/MANDATE.md || { echo "nested hook output mismatch"; exit 1; }
) || fail "fake consumer install check failed"

# --- 7. malformed managed input fails before changing consumer files ---
badproj="$tmp/badproj"
mkdir -p "$badproj/.codex/shared" "$badproj/.codex"
cp -a "$ROOT/." "$badproj/.codex/shared/"
printf '%s\n' '{broken' > "$badproj/.codex/hooks.json"
printf '%s\n' '# untouched' > "$badproj/AGENTS.md"
cp "$badproj/.codex/hooks.json" "$tmp/bad-hooks.before"
cp "$badproj/AGENTS.md" "$tmp/bad-agents.before"
if (cd "$badproj" && bash .codex/shared/install.sh >/dev/null 2>&1); then
  fail "installer accepted malformed hooks JSON"
fi
cmp -s "$badproj/.codex/hooks.json" "$tmp/bad-hooks.before" || fail "failed install changed hooks"
cmp -s "$badproj/AGENTS.md" "$tmp/bad-agents.before" || fail "failed install changed AGENTS.md"
[[ ! -e "$badproj/.agents" && ! -e "$badproj/.codex/agents" ]] || fail "failed preflight created managed directories"

# --- 8. active and historical files use Codex paths and terminology ---
stale='\.claude/|CLAUDE\.md|AskUserQuestion|subagent_type|model:[[:space:]]*(sonnet|haiku)|claude-code-action|Claude Code'
hits="$(rg -n -i "$stale" "$ROOT" \
  -g '!docs/decisions.md' \
  -g '!test/check.sh' \
  -g '!.git/**' || true)"
[[ -z "$hits" ]] || fail "stale runtime guidance remains:"$'\n'"$hits"
! rg -n 'docs/superpowers' "$ROOT" -g '!.git/**' -g '!test/check.sh' || fail "superpowers path remains referenced"

# --- 9. shell syntax, whitespace, and optional native Codex discovery ---
bash -n "$ROOT/install.sh" "$ROOT/hooks/mandate.sh" "$ROOT/test/check.sh"
git -C "$ROOT" diff --check
if command -v codex >/dev/null 2>&1; then
  smoke="$tmp/smoke"
  mkdir -p "$smoke/.codex/shared"
  cp -a "$ROOT/." "$smoke/.codex/shared/"
  git -C "$smoke" init -q
  (cd "$smoke" && bash .codex/shared/install.sh >/dev/null)
  codex --cd "$smoke" debug prompt-input 'Summarize active instructions.' > "$tmp/prompt.json"
  grep -qF 'blindspot-pass' "$tmp/prompt.json" || fail "Codex discovery did not expose blindspot-pass"
  grep -qF 'Blindspot Mandate' "$tmp/prompt.json" || fail "Codex discovery did not expose mandate guidance"
else
  echo "SKIP: codex binary unavailable; native discovery not checked"
fi

echo "OK: all checks passed"
