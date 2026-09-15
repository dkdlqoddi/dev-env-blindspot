#!/usr/bin/env bash
# Repo self-check: mandate hook, frontmatter lint, reference integrity, decisions table contract, installer upgrade and idempotency, retired names.
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
refs="$(grep -ho '`TypeName: [a-z-]*`' "$ROOT"/skills/*/SKILL.md | sed 's/.*`TypeName: \([a-z-]*\)`.*/\1/' | sort -u)" || true
[[ -n "$refs" ]] || fail "no TypeName references found in any SKILL.md — pattern drift?"
while read -r name; do
  [[ -f "$ROOT/agents/$name.md" ]] || fail "skills reference agent '$name' but agents/$name.md is missing"
done <<<"$refs"
for f in "$ROOT"/agents/*.md; do
  name="$(basename "$f" .md)"
  grep -q "\`TypeName: $name\`" "$ROOT"/skills/*/SKILL.md || fail "agents/$name.md is not referenced by any SKILL.md"
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

# --- 6. install.sh on a fake consumer upgrading from an older version: prunes stale links, keeps the project's own, idempotent ---
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/proj/.antigravity/shared"
cp -a "$ROOT/." "$tmp/proj/.antigravity/shared/"
(
  cd "$tmp/proj"
  mkdir -p .antigravity/skills/own-skill .antigravity/agents
  printf 'own\n' > .antigravity/skills/own-skill/SKILL.md                     # the project's own skill
  ln -s ../shared/skills/explainer .antigravity/skills/explainer               # left by the full version
  ln -s ../shared/agents/doc-verifier.md .antigravity/agents/doc-verifier.md   # left by the full version
  ln -s ../../vendor/own-agent.md .antigravity/agents/own-agent.md             # the project's own link: dangling, but outside shared
  printf '# proj\n' > ANTIGRAVITY.md
  links() { for l in .antigravity/skills/* .antigravity/agents/*; do printf '%s -> %s\n' "$l" "$(readlink "$l" || true)"; done; }
  bash .antigravity/shared/install.sh >/dev/null || { echo "install.sh failed"; exit 1; }
  cp .antigravity/settings.json ../settings.first; cp ANTIGRAVITY.md ../antigravity.first; links > ../links.first
  bash .antigravity/shared/install.sh >/dev/null || { echo "install.sh failed on second run"; exit 1; }
  cmp -s .antigravity/settings.json ../settings.first || { echo "settings.json rewritten on second run"; exit 1; }
  cmp -s ANTIGRAVITY.md ../antigravity.first || { echo "ANTIGRAVITY.md rewritten on second run"; exit 1; }
  [[ "$(links)" == "$(cat ../links.first)" ]] || { echo "links changed on second run"; exit 1; }
  [[ -L .antigravity/skills/blindspot-pass && -f .antigravity/skills/blindspot-pass/SKILL.md ]] || { echo "skill symlink missing or broken"; exit 1; }
  [[ -L .antigravity/agents/codebase-scanner.md && -f .antigravity/agents/codebase-scanner.md ]] || { echo "agent symlink missing or broken"; exit 1; }
  [[ "$(links | grep -c ' -> \.\./shared/')" == 2 ]] || { echo "expected exactly 2 links into shared:"; links; exit 1; }
  [[ ! -L .antigravity/skills/explainer && ! -L .antigravity/agents/doc-verifier.md ]] || { echo "stale shared links not pruned"; exit 1; }
  [[ -f .antigravity/skills/own-skill/SKILL.md && -L .antigravity/agents/own-agent.md ]] || { echo "the project's own skill or link was touched"; exit 1; }
  [[ ! -e docs ]] || { echo "install.sh created docs/"; exit 1; }
  [[ "$(grep -c 'mandate.sh' .antigravity/settings.json)" == 1 ]] || { echo "hook missing or duplicated"; exit 1; }
  [[ "$(grep -cxF '@.antigravity/shared/MANDATE.md' ANTIGRAVITY.md)" == 1 ]] || { echo "ANTIGRAVITY.md import missing or duplicated"; exit 1; }
) || fail "install check failed"

# --- 7. names retired with the full lifecycle must not survive in shipped files ---
retired=(requirements-interview explainer work-report blindspot-flow doc-verifier docs_check quiz.html docs/notes map.md rules.md specs/ '25 어절')
pats=(); for r in "${retired[@]}"; do pats+=(-e "$r"); done
hits="$(grep -rnF "${pats[@]}" "$ROOT/skills" "$ROOT/agents" "$ROOT/MANDATE.md" "$ROOT/install.sh" "$ROOT/README.md" "$ROOT/ANTIGRAVITY.md" || true)"
[[ -z "$hits" ]] || fail "retired name referenced:"$'\n'"$hits"

# --- 8. this repo's own decision record follows the template: same header, every row greppable and six cells wide ---
dec="$ROOT/docs/decisions.md"
[[ -f "$dec" ]] || fail "missing $dec"
grep -qxF "$HDR" "$dec" || fail "$dec: table header drifted from the template"
grep -qxF "$SEP" "$dec" || fail "$dec: missing table separator"
bad="$(awk -v sep="$SEP" 'f && !/^[|] 20/ {print NR": "$0} $0 == sep {f=1}' "$dec")"
[[ -z "$bad" ]] || fail "$dec: every line after the separator must be a row starting with '| 20' (a blank or unpiped line splits the table):"$'\n'"$bad"
bad="$(awk -F'|' '/^[|] 20/ && NF != 8 {print NR": "$0}' "$dec")"
[[ -z "$bad" ]] || fail "$dec: rows must have exactly 6 cells (no raw | inside a cell):"$'\n'"$bad"

echo "OK: all checks passed"
