#!/usr/bin/env bash
# Repo self-check: mandate hook, frontmatter lint, reference integrity, installer idempotency.
set -euo pipefail
shopt -s nullglob
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

# --- 1. mandate hook outputs the skill mapping ---
out="$(bash "$ROOT/hooks/mandate.sh")"
for skill in requirements-interview blindspot-pass explainer work-report blindspot-flow swarm-plan swarm-review; do
  grep -q "$skill" <<<"$out" || fail "mandate.sh output missing $skill"
done
for p in 'docs/<area>/rules.md' 'docs/<area>/map.md' 'docs/<area>/specs/<unit>.md' 'docs/quiz.html' 'docs/notes/' 'docs/swarm/'; do
  grep -qF "$p" <<<"$out" || fail "mandate.sh output missing tier path $p"
done

# --- 2. frontmatter lint (skills + agents) ---
files=("$ROOT"/skills/*/SKILL.md "$ROOT"/agents/*.md)
[[ ${#files[@]} -eq 13 ]] || fail "expected 13 lintable files (7 skills + 6 agents), got ${#files[@]}"
for f in "${files[@]}"; do
  [[ "$(head -n1 "$f")" == "---" ]] || fail "$f: missing frontmatter open"
  fm="$(awk '/^---$/{c++; next} c==1' "$f")"
  grep -q '^name:' <<<"$fm" || fail "$f: missing name"
  grep -q '^description:' <<<"$fm" || fail "$f: missing description"
done

# --- 2b. Antigravity-side lint: frontmatter contract of .agents/{skills,agents,rules} files (agy 1.1.27 / Antigravity 2.0) ---
ag=("$ROOT"/antigravity/skills/*/SKILL.md "$ROOT"/antigravity/agents/*.md "$ROOT"/antigravity/rules/*.md)
[[ ${#ag[@]} -eq 4 ]] || fail "expected 4 Antigravity files (1 skill + 2 agents + 1 rule), got ${#ag[@]}"
for f in "${ag[@]}"; do
  [[ "$(head -n1 "$f")" == "---" ]] || fail "$f: missing frontmatter open"
  fm="$(awk '/^---$/{c++; next} c==1' "$f")"
  case "$f" in
    */rules/*) grep -q '^trigger:' <<<"$fm" || fail "$f: rule needs trigger:" ;;
    *) grep -q '^name:' <<<"$fm" || fail "$f: missing name"; grep -q '^description:' <<<"$fm" || fail "$f: missing description" ;;
  esac
  if [[ "$f" == */agents/* ]]; then
    for kv in 'subagent: true' 'mainAgent: false' 'model: flash' 'commandExecutionPolicy: auto'; do grep -qx "$kv" <<<"$fm" || fail "$f: needs '$kv'"; done
    grep -qx 'tools:' <<<"$fm" || fail "$f: needs 'tools:' followed by a block sequence (one '  - name' per line) so the allowlist can be checked"
    tools="$(grep -o '^  - .*' <<<"$fm" | sed 's/  - //')"
    [[ -n "$tools" ]] || fail "$f: tools allowlist is empty (empty means no tools)"
    for t in $tools; do
      case " view_file run_command write_to_file replace_file_content find_by_name grep_search list_dir read_url_content search_web " in
        *" $t "*) ;; *) fail "$f: unknown Antigravity tool '$t'" ;;
      esac
    done
  fi
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
  grep -q "\`$name\`" "$ROOT/MANDATE.md" || fail "agents/$name.md is not named in MANDATE.md hard rule 2"
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
  bash .claude/shared/install-antigravity.sh >/dev/null
  ls -lR .agents > ../agents.first
  bash .claude/shared/install-antigravity.sh >/dev/null   # second run must change nothing
  ls -lR .agents | cmp -s - ../agents.first || { echo ".agents links rewritten on second run"; exit 1; }
  for l in .agents/skills/swarm-run/SKILL.md .agents/skills/swarm-run/templates/result.md .agents/agents/swarm-worker.md .agents/agents/swarm-checker.md .agents/rules/swarm-mandate.md; do
    [[ -f "$l" ]] || { echo "antigravity link $l missing or broken"; exit 1; }
  done
) || fail "install idempotency check failed"

# --- 6. countable limits: docs_check.py runs clean on every shipped template ---
python3 "$ROOT/skills/work-report/scripts/docs_check.py" \
  "$ROOT/skills/work-report/templates/quiz.html" \
  "$ROOT/skills/blindspot-pass/templates/rules.md" \
  "$ROOT/skills/blindspot-pass/templates/map.md" \
  "$ROOT/skills/explainer/templates/spec.md" >/dev/null \
  || fail "docs_check.py reported violations on the shipped templates"

# --- 7. retired per-cycle paths must not survive in shipped instructions ---
hits="$(grep -rn -e 'docs/blindspot' -e 'YYYY-MM-DD-' -e 'quiz_check.py' -e 'implementation-notes' "$ROOT/skills" "$ROOT/agents" "$ROOT/antigravity" "$ROOT/MANDATE.md" || true)"
[[ -z "$hits" ]] || fail "retired path referenced:"$'\n'"$hits"

# --- 8. template heading contract: skills write sections by heading name ---
need() { local f="$1"; shift; for h in "$@"; do grep -qxF "## $h" "$f" || fail "$f: missing heading '## $h'"; done; }
need "$ROOT/skills/blindspot-pass/templates/rules.md" "불변 규칙" "관례" "표준 명령" "용어"
need "$ROOT/skills/blindspot-pass/templates/map.md" "영역 개요" "단위" "주요 흐름" "통합 지점" "알려진 위험"
need "$ROOT/skills/explainer/templates/spec.md" "목적과 배경" "요구사항" "동작 방식" "결정 기록" "엣지케이스와 제약" "의도적 범위 제외" "열린 질문" "변경 이력"
grep -q '^## YYYY-MM-DD HH:MM' "$ROOT/skills/work-report/templates/notes.md" || fail "notes.md: missing entry heading"
need "$ROOT/skills/swarm-plan/templates/plan.md" "목표" "작업" "회차"
need "$ROOT/skills/swarm-plan/templates/task.md" "목표" "해야 할 일" "완료 조건" "검증"
need "$ROOT/antigravity/skills/swarm-run/templates/status.md" "작업" "웨이브 검증"
for b in '상태' '검증' '결정' '막힌 것'; do grep -q "^- $b:" "$ROOT/antigravity/skills/swarm-run/templates/result.md" || fail "result.md: missing bullet '- $b:'"; done

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

# --- 10. every templates/<file> named in a SKILL.md ships in some skill (Claude side and Antigravity side each resolve within their own tree) ---
agtpls="$(grep -ho 'templates/[A-Za-z0-9_.-]*' "$ROOT"/antigravity/skills/*/SKILL.md | sed 's#templates/##' | sort -u || true)"
while read -r t; do
  [[ -z "$t" ]] && continue
  found=0; for f in "$ROOT"/antigravity/skills/*/templates/"$t"; do [[ -f "$f" ]] && found=1; done
  [[ $found == 1 ]] || fail "an Antigravity SKILL.md references templates/$t but no Antigravity skill ships it"
done <<<"$agtpls"
tpls="$(grep -ho 'templates/[A-Za-z0-9_.-]*' "$ROOT"/skills/*/SKILL.md | sed 's#templates/##' | sort -u || true)"
[[ -n "$tpls" ]] || fail "no templates/<file> references found in any SKILL.md — pattern drift?"
while read -r t; do
  found=0
  for f in "$ROOT"/skills/*/templates/"$t"; do [[ -f "$f" ]] && found=1; done
  [[ $found == 1 ]] || fail "a SKILL.md references templates/$t but no skill ships it"
done <<<"$tpls"

# --- 12. swarm_check.py: clean on a valid package, loud on a broken one ---
sw="$tmp/sw/docs/swarm"; mkdir -p "$sw/tasks" "$tmp/sw/src"; : > "$tmp/sw/src/a.py"; : > "$tmp/sw/src/b.py"
printf '# x 스웜 계획\n\n- 기준 커밋: abc1234\n- 대상 spec: docs/core/specs/x.md\n- 작업 노트: docs/notes/x.md\n- 동시 실행 상한: 8\n- 전체 검증: `true`\n\n## 목표\n\nx\n\n## 작업\n\n| id | 제목 | 역할 | 웨이브 | 선행 |\n|---|---|---|---|---|\n| T01 | a | 구현 | 1 | 없음 |\n| T02 | b | 테스트 | 2 | T01 |\n\n## 회차\n\n| 회차 | 날짜 | 범위 | 비고 |\n|---|---|---|---|\n| 1 | 2026-01-01 | 전체 | |\n' > "$sw/plan.md"
brief() { printf '# %s x\n\n- 역할: 구현\n- 웨이브: %s\n- 선행: %s\n- 소유 파일: %s\n\n## 목표\n\nx\n\n## 해야 할 일\n\n1. x\n\n## 완료 조건\n\n- [ ] x\n\n## 검증\n\n`true`\n' "$1" "$2" "$3" "$4"; }
brief T01 1 없음 '`src/a.py`, `src/new.py` (신규)' > "$sw/tasks/T01.md"
brief T02 2 T01 '`src/b.py`' > "$sw/tasks/T02.md"
python3 "$ROOT/skills/swarm-plan/scripts/swarm_check.py" "$sw/plan.md" >/dev/null || fail "swarm_check.py rejected a valid package"
brief T02 1 T03 '`src`, `src/missing.py`' > "$sw/tasks/T02.md"   # same 웨이브 as T01, owns the directory without a trailing slash (overlaps src/a.py), dep on a later 웨이브, missing path
brief T03 2 없음 '`src/b.py`' > "$sw/tasks/T03.md"
sed -i 's/| T02 | b | 테스트 | 2 | T01 |/| T02 | b | 테스트 | 1 | T03 |\n| T03 | c | 문서 | 2 | 없음 |\n| T04 | d | 정리 | 2 | 없음 |/' "$sw/plan.md"   # T04 has no brief
printf '\n[제목]\n' >> "$sw/tasks/T01.md"
sed -i 's/^1\. x$/1. 필요하면 x/' "$sw/tasks/T01.md"                       # delegating word inside 해야 할 일
sed -i 's/^- 전체 검증: `true`$/- 전체 검증: `(rules.md 표준 명령의 test 명령)`/' "$sw/plan.md"   # template guidance left in
if out="$(python3 "$ROOT/skills/swarm-plan/scripts/swarm_check.py" "$sw/plan.md" 2>&1)"; then
  fail "swarm_check.py exited 0 on a broken package"
fi
for msg in 'overlap' 'earlier 웨이브' 'is missing' 'does not exist' 'placeholder' '필요하면' 'template guidance'; do
  grep -q "$msg" <<<"$out" || fail "swarm_check.py fixture output missing '$msg'"
done

# --- 11. MANDATE.md is injected into every consumer session twice (hook + @import): keep it small ---
[[ "$(wc -l < "$ROOT/MANDATE.md")" -le 60 ]] || fail "MANDATE.md over 60 lines"

echo "OK: all checks passed"
