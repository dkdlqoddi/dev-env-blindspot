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
for p in 'docs/<area>/rules.md' 'docs/<area>/map.md' 'docs/<area>/specs/<unit>.md' 'docs/quiz.html' 'docs/notes/'; do
  grep -qF "$p" <<<"$out" || fail "mandate.sh output missing tier path $p"
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
for f in "$ROOT"/agents/*.md; do
  name="$(basename "$f" .md)"
  grep -q "subagent_type: \`$name\`" "$ROOT"/skills/*/SKILL.md || fail "agents/$name.md is not referenced by any SKILL.md"
done

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

# --- 6. countable limits: docs_check.py runs clean on every shipped template ---
python3 "$ROOT/skills/work-report/scripts/docs_check.py" \
  "$ROOT/skills/work-report/templates/quiz.html" \
  "$ROOT/skills/blindspot-pass/templates/rules.md" \
  "$ROOT/skills/blindspot-pass/templates/map.md" \
  "$ROOT/skills/explainer/templates/spec.md" >/dev/null \
  || fail "docs_check.py reported violations on the shipped templates"

# --- 9. docs_check.py must fail loudly on broken tier files (negative fixture) ---
fx="$tmp/fx/area"; mkdir -p "$fx/specs"
printf '# r\n%.0s' $(seq 61) > "$fx/rules.md"
printf '# m\n\n## 단위\n\n| 단위 | 하는 일 | 위치 | 상세 명세 |\n|---|---|---|---|\n| a | x | src/a | specs/missing.md |\n' > "$fx/map.md"
{ printf '# s\n\n## 목적과 배경\n\n'; printf '%s ' $(seq 30); printf '끝.\n\n## 요구사항\n\n## 동작 방식\n\n## 의도적 범위 제외\n\n'; printf 'x\n%.0s' $(seq 200); } > "$fx/specs/orphan.md"
if out="$(python3 "$ROOT/skills/work-report/scripts/docs_check.py" "$fx/rules.md" "$fx/map.md" "$fx/specs/orphan.md" 2>&1)"; then
  fail "docs_check.py exited 0 on a broken fixture"
fi
for msg in 'max 60' 'does not exist' 'not listed' 'max 200' '어절'; do
  grep -q "$msg" <<<"$out" || fail "docs_check.py fixture output missing '$msg'"
done

# --- 8. template heading contract: skills write sections by heading name ---
need() { local f="$1"; shift; for h in "$@"; do grep -qxF "## $h" "$f" || fail "$f: missing heading '## $h'"; done; }
need "$ROOT/skills/blindspot-pass/templates/rules.md" "불변 규칙" "관례" "표준 명령" "용어"
need "$ROOT/skills/blindspot-pass/templates/map.md" "영역 개요" "단위" "주요 흐름" "통합 지점" "알려진 위험"
need "$ROOT/skills/explainer/templates/spec.md" "목적과 배경" "요구사항" "동작 방식" "결정 기록" "엣지케이스와 제약" "의도적 범위 제외" "열린 질문" "변경 이력"
grep -q '^## YYYY-MM-DD HH:MM' "$ROOT/skills/work-report/templates/notes.md" || fail "notes.md: missing entry heading"

# --- 7. retired per-cycle paths must not survive in shipped instructions ---
hits="$(grep -rn -e 'docs/blindspot' -e 'YYYY-MM-DD-' -e 'quiz_check.py' -e 'implementation-notes' "$ROOT/skills" "$ROOT/agents" "$ROOT/MANDATE.md" || true)"
[[ -z "$hits" ]] || fail "retired path referenced:"$'\n'"$hits"

# --- 10. every templates/<file> named in a SKILL.md ships in some skill ---
while read -r t; do
  found=0
  for f in "$ROOT"/skills/*/templates/"$t"; do [[ -f "$f" ]] && found=1; done
  [[ $found == 1 ]] || fail "a SKILL.md references templates/$t but no skill ships it"
done < <(grep -ho 'templates/[A-Za-z0-9_.-]*' "$ROOT"/skills/*/SKILL.md | sed 's#templates/##' | sort -u)

# --- 11. MANDATE.md is injected into every consumer session twice (hook + @import): keep it small ---
[[ "$(wc -l < "$ROOT/MANDATE.md")" -le 60 ]] || fail "MANDATE.md over 60 lines"

echo "OK: all checks passed"
