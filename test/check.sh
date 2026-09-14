#!/usr/bin/env bash
# Repo self-check: mandate hook, frontmatter lint, reference integrity, decisions table contract, installer idempotency, retired names.
set -euo pipefail
shopt -s nullglob
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

# --- 1. mandate hook injects the session rules ---
out="$(bash "$ROOT/hooks/mandate.sh")"
for s in '# Blindspot Mandate' 'blindspot-pass' 'docs/decisions.md'; do
  grep -qF "$s" <<<"$out" || fail "mandate.sh output missing '$s'"
done

# --- 2. MANDATE.md is injected into every consumer session twice (hook + @import): keep it tiny ---
[[ "$(wc -l < "$ROOT/MANDATE.md")" -le 10 ]] || fail "MANDATE.md over 10 lines"

# --- 3. frontmatter lint (one skill + one agent) ---
files=("$ROOT"/skills/*/SKILL.md "$ROOT"/agents/*.md)
[[ ${#files[@]} -eq 2 ]] || fail "expected 2 lintable files (1 skill + 1 agent), got ${#files[@]}"
for f in "${files[@]}"; do
  [[ "$(head -n1 "$f")" == "---" ]] || fail "$f: missing frontmatter open"
  fm="$(awk '/^---$/{c++; next} c==1' "$f")"
  grep -q '^name:' <<<"$fm" || fail "$f: missing name"
  grep -q '^description:' <<<"$fm" || fail "$f: missing description"
done

# --- 4. skill ↔ agent reference integrity, both directions (agent rename tripwire) ---
refs="$(grep -ho 'subagent_type: `[a-z-]*`' "$ROOT"/skills/*/SKILL.md | sed 's/.*`\([a-z-]*\)`.*/\1/' | sort -u)" || true
[[ -n "$refs" ]] || fail "no subagent_type references found in any SKILL.md — pattern drift?"
while read -r name; do
  [[ -f "$ROOT/agents/$name.md" ]] || fail "skills reference agent '$name' but agents/$name.md is missing"
done <<<"$refs"
for f in "$ROOT"/agents/*.md; do
  name="$(basename "$f" .md)"
  grep -q "subagent_type: \`$name\`" "$ROOT"/skills/*/SKILL.md || fail "agents/$name.md is not referenced by any SKILL.md"
done

# --- 5. decisions table contract: the skill writes rows by column order, so template and skill must agree ---
HDR='| 날짜 | 영역 | 결정 | 근거 | 기각한 대안 | 결정 주체 |'
SEP='|---|---|---|---|---|---|'
SKILL="$ROOT/skills/blindspot-pass/SKILL.md"
tpl="$ROOT/skills/blindspot-pass/templates/decisions.md"
[[ -f "$tpl" ]] || fail "missing $tpl"
grep -qxF '# 결정 기록' "$tpl" || fail "$tpl: missing title '# 결정 기록'"
grep -qxF "$HDR" "$tpl" || fail "$tpl: table header drifted"
grep -qxF "$SEP" "$tpl" || fail "$tpl: missing table separator"
! grep -q '^| 20' "$tpl" || fail "$tpl: ships a row — grep would count it as a decision"
grep -qF 'templates/decisions.md' "$SKILL" || fail "$SKILL: does not name templates/decisions.md"
grep -qF '날짜 | 영역 | 결정 | 근거 | 기각한 대안 | 결정 주체' "$SKILL" || fail "$SKILL: row format drifted from the template header"

# --- 6. install.sh idempotency (fake consumer project) ---
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

# --- 7. names retired with the full lifecycle must not survive in shipped files ---
retired=(requirements-interview explainer work-report blindspot-flow doc-verifier docs_check quiz.html docs/notes map.md rules.md specs/ '25 어절')
pats=(); for r in "${retired[@]}"; do pats+=(-e "$r"); done
hits="$(grep -rnF "${pats[@]}" "$ROOT/skills" "$ROOT/agents" "$ROOT/MANDATE.md" || true)"
[[ -z "$hits" ]] || fail "retired name referenced:"$'\n'"$hits"

echo "OK: all checks passed"
