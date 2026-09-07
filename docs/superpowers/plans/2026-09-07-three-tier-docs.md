# 3계층 문서 구조 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 라이프사이클 스킬 다섯 개의 산출물을 날짜 붙은 사이클별 문서에서 영역별 고정 3계층 문서(`rules.md` / `map.md` / `specs/<단위>.md`)로 바꾸고, 퀴즈는 한 파일, 구현 노트는 인수 시 삭제되는 작업 파일로 만든다.

**Architecture:** 스킬·에이전트의 이름과 수는 그대로 두고 본문만 바꾼다. 템플릿 5개가 기존 6개를 대체하고, `quiz_check.py`는 `docs_check.py`로 확장되어 퀴즈·계층 줄 상한·맵 링크·spec 문장을 검사한다. MANDATE에는 계층 표와 읽기 순서만 추가하고 라우팅 세부는 각 SKILL.md에 둔다. `test/check.sh`가 폐지 경로·헤딩 계약·음성 fixture로 회귀를 막는다.

**Tech Stack:** Markdown 지침 파일(영어), 한국어 템플릿, Python 3 표준 라이브러리(`re`, `os`), bash 테스트 스크립트.

**Spec:** `docs/superpowers/specs/2026-09-07-three-tier-docs-design.md` — 각 태스크는 스펙 섹션 번호를 인용한다. 실행자는 스펙을 먼저 읽는다.

## Global Constraints

- 지침 파일(`SKILL.md`, `agents/*.md`, `MANDATE.md`)은 영어. 산출물·템플릿 본문은 한국어. 템플릿의 지시 주석(`<!-- -->`)은 영어. (CLAUDE.md Conventions)
- 스킬 폴더 이름 5개, 에이전트 파일 이름 5개, `hooks/mandate.sh`, `MANDATE.md` 경로는 바꾸지 않는다. `install.sh`는 손대지 않는다. (스펙 §9)
- 가독성 표준 문구와 `25 어절` 표지는 requirements-interview, blindspot-pass, explainer, work-report 네 SKILL.md에 정확히 남는다. `bash test/check.sh` 검사 4가 `-eq 4`를 유지한다.
- 모든 SKILL.md는 `## Gotchas` 섹션을 유지한다. 기존 항목은 삭제하지 않고, 사실이 아니게 된 항목만 새 대상을 가리키도록 고쳐 쓴다. (스펙 §6.7)
- 줄 상한: `rules.md` 60, `map.md` 150, `specs/*.md` 200, `MANDATE.md` 60. (스펙 §2-10, §10-11)
- 산출물 경로: `docs/<area>/rules.md`, `docs/<area>/map.md`, `docs/<area>/specs/<unit>.md`, `docs/notes/<slug>.md`, `docs/quiz.html`. 문자열 `docs/blindspot`, `YYYY-MM-DD-`, `quiz_check.py`, `implementation-notes`는 `skills/`, `agents/`, `MANDATE.md` 어디에도 남지 않는다. (스펙 §10-7)
- 모든 커밋 직전에 `bash test/check.sh`가 `OK: all checks passed`를 출력해야 한다.
- 커밋 메시지 끝에 붙일 두 줄:
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`
  `Claude-Session: https://claude.ai/code/session_01CiaPDvfNYrqWaeiYg8XXVe`

---

## 파일 구조

| 파일 | 상태 | 책임 |
|---|---|---|
| `skills/work-report/scripts/docs_check.py` | `quiz_check.py`에서 개명·확장 | 퀴즈 문장/보기 길이, 계층 줄 상한, 맵 링크 무결성, spec 비개발자 섹션 문장 길이 |
| `skills/blindspot-pass/templates/rules.md` | 신설 | Tier 1 템플릿 |
| `skills/blindspot-pass/templates/map.md` | 신설 | Tier 2 템플릿 |
| `skills/explainer/templates/spec.md` | 신설 | Tier 3 템플릿 |
| `skills/work-report/templates/notes.md` | 신설 | 작업 노트 템플릿 |
| `skills/work-report/templates/quiz.html` | 수정 | meta 줄 추가 |
| `skills/requirements-interview/templates/requirements.md`, `skills/blindspot-pass/templates/unknowns.md`, `skills/explainer/templates/explainer.md`, `skills/work-report/templates/report.md`, `skills/work-report/templates/implementation-notes.md` | 삭제 | — |
| `agents/codebase-scanner.md`, `agents/domain-researcher.md`, `agents/doc-verifier.md`, `agents/change-analyzer.md` | 본문 수정 | 계층 입력, 반영 계층 출력, 계층 위치 검사, 문서 갱신 필요 |
| `skills/*/SKILL.md` (5개) | 전면 재작성 | 계층을 읽고 쓰는 워크플로우 |
| `MANDATE.md` | 수정 | 계층 표 + 읽기 순서, hard rule 4·5, 질문 정책 1 |
| `test/check.sh` | 수정 | 검사 6 대상 교체, 검사 7·8·9·10·11 신설, 검사 1·3 확장 |
| `README.md`, `CLAUDE.md` | 수정 | 소비자 가이드·저장소 지침 동기화 |
| `docs/core/rules.md`, `docs/core/map.md`, `docs/core/specs/lifecycle-skills.md`, `docs/quiz.html` | 신설 | 이 저장소 자체의 3계층 문서와 이번 사이클 퀴즈(실전 검증) |

작업 순서는 매 커밋에서 `test/check.sh`가 통과하도록 잡았다. Task 2에서 옛 템플릿을 지우면 SKILL.md가 잠시 없는 파일을 가리키지만, 그것을 잡는 검사 10은 SKILL.md가 모두 새로 쓰인 Task 8에서 켠다.

---

### Task 1: docs_check.py — 퀴즈 검사기를 계층 검사기로 확장

**Files:**
- Create: `skills/work-report/scripts/docs_check.py` (`git mv`로 `quiz_check.py`에서)
- Modify: `test/check.sh` (검사 6의 스크립트 이름, 검사 9 신설)

**Interfaces:**
- Produces: `python3 docs_check.py <path>...` — 경로 모양으로 분기한다. 상위 폴더 이름이 `specs`면 Tier 3, 아니면 파일명 `rules.md`는 Tier 1, `map.md`는 Tier 2, `spec.md`는 Tier 3, `.html`은 퀴즈, 그 외는 검사 없음. 위반 목록을 출력하고 exit 1, 없으면 `OK`와 exit 0. 위반 메시지에 `max 60` / `max 150` / `max 200` / `does not exist` / `not listed` / `어절` 문자열이 들어간다. 이후 모든 스킬이 이 경로로 호출한다: `.claude/skills/work-report/scripts/docs_check.py`.

- [ ] **Step 1: 실패하는 검사 추가 — check.sh 검사 6의 스크립트 이름을 바꾸고 검사 9(음성 fixture)를 넣는다**

`test/check.sh`에서 `# --- 6.` 블록을 아래로 교체한다.

```bash
# --- 6. countable readability limits: checker runs clean on the shipped templates ---
python3 "$ROOT/skills/work-report/scripts/docs_check.py" \
  "$ROOT/skills/work-report/templates/quiz.html" \
  "$ROOT/skills/work-report/templates/report.md" >/dev/null \
  || fail "docs_check.py reported violations on the work-report templates"
```

그리고 그 블록 바로 뒤, 마지막 `echo "OK: all checks passed"` 앞에 아래를 추가한다. `$tmp`는 검사 5가 만든 임시 폴더다.

```bash
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
```

- [ ] **Step 2: 실패 확인**

Run: `bash test/check.sh`
Expected: `FAIL: docs_check.py reported violations on the work-report templates` (파일이 아직 없어 python3가 `can't open file`로 실패).

- [ ] **Step 3: 스크립트 개명 후 내용 전체 교체**

```bash
git mv skills/work-report/scripts/quiz_check.py skills/work-report/scripts/docs_check.py
```

`skills/work-report/scripts/docs_check.py` 전체를 아래로 교체한다.

```python
#!/usr/bin/env python3
"""Mechanical checks for blindspot deliverables (quiz + tier documents).

Usage: python3 docs_check.py <path> [<path> ...]

Dispatch by path shape:
  parent directory named 'specs' -> Tier 3 spec
  basename rules.md              -> Tier 1
  basename map.md                -> Tier 2
  basename spec.md               -> Tier 3 (the shipped template)
  *.html                         -> pre-merge quiz
  anything else                  -> no checks (notes etc.)

Checks:
  quiz   : every sentence in the 변경 요약 block and every QUESTIONS q/explain has
           at most 25 어절 (whitespace-separated words); every option has at most
           40 characters
  Tier 1 : at most 60 lines
  Tier 2 : at most 150 lines; a 상세 명세 cell starting with specs/ must name a
           file that exists next to the map; every specs/*.md next to the map
           must be named by some 단위 row
  Tier 3 : at most 200 lines; sentences under 목적과 배경 / 요구사항 / 동작 방식 /
           의도적 범위 제외 have at most 25 어절

Prints violations and exits 1; exits 0 when clean.
"""
import os
import re
import sys

MAX_EOJEOL = 25
MAX_OPTION_CHARS = 40
CAPS = {1: 60, 2: 150, 3: 200}
PROSE_SECTIONS = ("목적과 배경", "요구사항", "동작 방식", "의도적 범위 제외")

# ponytail: regex over the templates' fixed shapes and a rough [.?!]+space
# sentence split; a real markdown/Korean parser only if the shapes change or
# quoted-sentence merging becomes a recurring miss.


def sentences(text):
    for s in re.split(r"(?<=[.?!])\s+", text.strip()):
        s = s.strip()
        if s:
            yield s


def eojeol_count(sentence):
    return len([t for t in sentence.split() if any(c.isalnum() for c in t)])


def unescape_js(s):
    return s.replace('\\"', '"').replace("\\\\", "\\")


def strip_comments(text):
    return re.sub(r"\s+", " ", re.sub(r"<!--.*?-->", " ", text, flags=re.S))


def check_prose(text, where, violations):
    for s in sentences(text):
        n = eojeol_count(s)
        if n > MAX_EOJEOL:
            violations.append(f'{where}: sentence has {n} 어절 (max {MAX_EOJEOL}): "{s}"')


def check_quiz(src, violations):
    m = re.search(r'<div class="summary">(.*?)</div>', src, re.S)
    if m:
        text = re.sub(r"<[^>]+>", " ", re.sub(r"<!--.*?-->", " ", m.group(1), flags=re.S))
        check_prose(re.sub(r"\s+", " ", text), "변경 요약", violations)
    else:
        violations.append('summary block (<div class="summary">) not found')
    m = re.search(r"const QUESTIONS = \[(.*?)\];", src, re.S)
    if not m:
        violations.append("QUESTIONS array not found")
        return
    body = m.group(1)
    for i, q in enumerate(re.finditer(r'\bq\s*:\s*"((?:[^"\\]|\\.)*)"', body), 1):
        check_prose(unescape_js(q.group(1)), f"Q{i} question", violations)
    for i, opts in enumerate(re.finditer(r"\boptions\s*:\s*\[(.*?)\]", body, re.S), 1):
        for o in re.finditer(r'"((?:[^"\\]|\\.)*)"', opts.group(1)):
            text = unescape_js(o.group(1))
            if len(text) > MAX_OPTION_CHARS:
                violations.append(
                    f'Q{i} option has {len(text)} chars (max {MAX_OPTION_CHARS}): "{text}"'
                )
    for i, ex in enumerate(re.finditer(r'\bexplain\s*:\s*"((?:[^"\\]|\\.)*)"', body), 1):
        check_prose(unescape_js(ex.group(1)), f"Q{i} explain", violations)


def tier_of(path):
    parent = os.path.basename(os.path.dirname(os.path.abspath(path)))
    if parent == "specs":
        return 3
    return {"rules.md": 1, "map.md": 2, "spec.md": 3}.get(os.path.basename(path))


def section(src, heading):
    m = re.search(rf"^## {re.escape(heading)}\s*$(.*?)(?=^## |\Z)", src, re.S | re.M)
    return m.group(1) if m else None


def table_rows(body):
    """Rows of the markdown tables in body, as lists of cell strings (separator rows skipped)."""
    for line in body.splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if not cells[0] or set(cells[0]) <= set("-: "):
            continue
        yield cells


def check_cap(src, tier, violations):
    n = len(src.splitlines())
    if n > CAPS[tier]:
        violations.append(f"Tier {tier} file has {n} lines (max {CAPS[tier]})")


def check_map(path, src, violations):
    check_cap(src, 2, violations)
    body = section(src, "단위")
    if body is None:
        violations.append("'## 단위' section not found")
        return
    here = os.path.dirname(os.path.abspath(path))
    listed = set()
    for cells in table_rows(body):
        if cells[0] == "단위" or len(cells) < 4:
            continue
        ref = cells[3]
        if ref.startswith("specs/"):
            target = os.path.normpath(os.path.join(here, ref))
            listed.add(target)
            if not os.path.isfile(target):
                violations.append(f"단위 '{cells[0]}': 상세 명세 {ref} does not exist")
    specs_dir = os.path.join(here, "specs")
    if os.path.isdir(specs_dir):
        for name in sorted(os.listdir(specs_dir)):
            target = os.path.normpath(os.path.join(specs_dir, name))
            if name.endswith(".md") and target not in listed:
                violations.append(f"specs/{name} is not listed in any 단위 row")


def check_spec(src, violations):
    check_cap(src, 3, violations)
    for heading in PROSE_SECTIONS:
        body = section(src, heading)
        if body is None:
            violations.append(f"'## {heading}' section not found")
            continue
        check_prose(strip_comments(body), heading, violations)


def check_file(path, violations):
    with open(path, encoding="utf-8") as f:
        src = f.read()
    found = []
    if path.endswith(".html"):
        check_quiz(src, found)
    else:
        tier = tier_of(path)
        if tier == 1:
            check_cap(src, 1, found)
        elif tier == 2:
            check_map(path, src, found)
        elif tier == 3:
            check_spec(src, found)
    violations.extend(f"{path}: {v}" for v in found)


def main(argv):
    if not argv:
        print("usage: docs_check.py <quiz.html|rules.md|map.md|specs/*.md> [...]", file=sys.stderr)
        return 2
    violations = []
    for path in argv:
        check_file(path, violations)
    if violations:
        for v in violations:
            print(v)
        print(f"{len(violations)} violation(s)")
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
```

- [ ] **Step 4: 통과 확인**

Run: `bash test/check.sh`
Expected: `OK: all checks passed`.

추가 확인: `python3 skills/work-report/scripts/docs_check.py skills/work-report/templates/quiz.html` → `OK`. `python3 skills/work-report/scripts/docs_check.py skills/work-report/templates/report.md` → `OK` (분기 없음).

- [ ] **Step 5: Commit**

```bash
git add -A skills/work-report/scripts test/check.sh
git commit -m "feat: extend quiz_check.py into docs_check.py with tier caps, map link integrity, and spec prose checks"
```

---
### Task 2: 템플릿 — 계층 템플릿 4개 신설, 옛 템플릿 5개 삭제, 퀴즈 meta 줄

**Files:**
- Create: `skills/blindspot-pass/templates/rules.md`, `skills/blindspot-pass/templates/map.md`, `skills/explainer/templates/spec.md`, `skills/work-report/templates/notes.md`
- Modify: `skills/work-report/templates/quiz.html` (CSS 한 줄, `<h1>` 뒤 meta 줄), `test/check.sh` (검사 6 인자, 검사 8 신설)
- Delete: `skills/requirements-interview/templates/requirements.md`, `skills/blindspot-pass/templates/unknowns.md`, `skills/explainer/templates/explainer.md`, `skills/work-report/templates/report.md`, `skills/work-report/templates/implementation-notes.md`

**Interfaces:**
- Consumes: Task 1의 `docs_check.py` (템플릿이 검사를 통과해야 함)
- Produces: 스킬이 헤딩 이름으로 쓰는 섹션 계약. rules.md: `## 불변 규칙`, `## 관례`, `## 표준 명령`, `## 용어`. map.md: `## 영역 개요`, `## 단위`, `## 주요 흐름`, `## 통합 지점`, `## 알려진 위험`. spec.md: `## 목적과 배경`, `## 요구사항`, `## 동작 방식`, `## 결정 기록`, `## 엣지케이스와 제약`, `## 의도적 범위 제외`, `## 열린 질문`, `## 변경 이력`. notes.md: 항목 헤딩 `## YYYY-MM-DD HH:MM — [결정 제목]`. 결정 기록 열: `날짜 | 결정 | 근거 | 기각한 대안 | 결정 주체`. 단위 열: `단위 | 하는 일 | 위치 | 상세 명세`.

- [ ] **Step 1: 실패하는 검사 추가 — 검사 6 인자를 새 템플릿으로 바꾸고 검사 8(헤딩 계약)을 넣는다**

`test/check.sh`의 `# --- 6.` 블록을 아래로 교체한다.

```bash
# --- 6. countable limits: docs_check.py runs clean on every shipped template ---
python3 "$ROOT/skills/work-report/scripts/docs_check.py" \
  "$ROOT/skills/work-report/templates/quiz.html" \
  "$ROOT/skills/blindspot-pass/templates/rules.md" \
  "$ROOT/skills/blindspot-pass/templates/map.md" \
  "$ROOT/skills/explainer/templates/spec.md" >/dev/null \
  || fail "docs_check.py reported violations on the shipped templates"
```

검사 9 블록 뒤(마지막 `echo` 앞)에 추가한다.

```bash
# --- 8. template heading contract: skills write sections by heading name ---
need() { local f="$1"; shift; for h in "$@"; do grep -qxF "## $h" "$f" || fail "$f: missing heading '## $h'"; done; }
need "$ROOT/skills/blindspot-pass/templates/rules.md" "불변 규칙" "관례" "표준 명령" "용어"
need "$ROOT/skills/blindspot-pass/templates/map.md" "영역 개요" "단위" "주요 흐름" "통합 지점" "알려진 위험"
need "$ROOT/skills/explainer/templates/spec.md" "목적과 배경" "요구사항" "동작 방식" "결정 기록" "엣지케이스와 제약" "의도적 범위 제외" "열린 질문" "변경 이력"
grep -q '^## YYYY-MM-DD HH:MM' "$ROOT/skills/work-report/templates/notes.md" || fail "notes.md: missing entry heading"
```

- [ ] **Step 2: 실패 확인**

Run: `bash test/check.sh`
Expected: `FAIL: docs_check.py reported violations on the shipped templates` (rules.md 등이 아직 없음).

- [ ] **Step 3: 옛 템플릿 삭제, 새 템플릿 4개 작성**

```bash
git rm -q skills/requirements-interview/templates/requirements.md skills/blindspot-pass/templates/unknowns.md skills/explainer/templates/explainer.md skills/work-report/templates/report.md skills/work-report/templates/implementation-notes.md
rmdir skills/requirements-interview/templates 2>/dev/null || true   # git rm already drops an emptied dir
```

`skills/blindspot-pass/templates/rules.md`:

```markdown
# [영역] 전역 규칙 (Tier 1)

- 최종 갱신: YYYY-MM-DD
- 코드 루트: (이 영역의 코드 경로)
- 읽는 법: 이 영역의 코드를 바꾸기 전에 항상 먼저 읽는다. 60줄을 넘기지 않는다.

<!-- Tier 1 is read before every change in this area, so every line must earn its place. A rule that binds one unit belongs in that unit's spec (엣지케이스와 제약), not here. 규칙 / 깨지면 생기는 일 / 쉬운 말 설명 cells: plain Korean for non-developers. 근거 / 명령 / 출처 cells: path:line, commands, URLs — technical. Append new rows at the end of a table. -->

## 불변 규칙

| # | 규칙 | 깨지면 생기는 일 | 근거 |
|---|---|---|---|

## 관례

<!-- 분류 is one of: 이름 짓기 / 폴더 구조 / 오류 처리 / 로그 / 테스트 / 의존성 -->

| 분류 | 관례 | 근거 |
|---|---|---|

## 표준 명령

<!-- test / lint / build / run. work-report hands these to check-runner verbatim. -->

| 목적 | 명령 |
|---|---|

## 용어

<!-- Only terms used by two or more units. Domain terms cite their source URL. -->

| 용어 | 쉬운 말 설명 | 출처 |
|---|---|---|
```

`skills/blindspot-pass/templates/map.md`:

```markdown
# [영역] 시스템 맵 (Tier 2)

- 최종 갱신: YYYY-MM-DD
- 코드 루트: (이 영역의 코드 경로)
- 읽는 법: 이 영역을 건드리는 작업이 rules.md 다음에 읽는다. 상세는 '단위' 표의 상세 명세로 내려간다. 150줄을 넘기지 않는다.

<!-- Append new rows at the END of each table so parallel branches conflict on single lines only. 영역 개요 and 하는 일 cells: plain Korean. 위치 / 계약 위치 / 거치는 단위 순서 cells: technical. -->

## 영역 개요

(3–5문장. 이 영역이 무엇을 책임지고 무엇을 책임지지 않는지, 코드를 본 적 없는 독자 기준)

## 단위

<!-- 단위 = kebab-case id = the spec filename specs/<단위>.md. 위치 = path or glob. 상세 명세 = specs/<단위>.md, or 없음 until a task first touches the unit. Never create a spec for every row at bootstrap. -->

| 단위 | 하는 일 | 위치 | 상세 명세 |
|---|---|---|---|

## 주요 흐름

| 흐름 | 시작점 | 거치는 단위 순서 |
|---|---|---|

## 통합 지점

<!-- 상대 = the other area, an external service, a database, CI. 계약 위치 = the file that defines the contract (schema, types, OpenAPI). -->

| 상대 | 방식 | 계약 위치 | 관련 단위 |
|---|---|---|---|

## 알려진 위험

<!-- Only risks that name two or more units. A single-unit risk goes to that unit's spec. -->

| 위험 | 영향 단위 | 상태 |
|---|---|---|
```

`skills/explainer/templates/spec.md`:

```markdown
# [단위] 상세 명세 (Tier 3)

- 영역: (frontend | backend | core)
- 위치: (코드 경로 — 맵 단위 표와 동일)
- 최종 갱신: YYYY-MM-DD
- 상태: 초안 | 확정
- 읽는 법: '목적과 배경', '요구사항', '동작 방식', '의도적 범위 제외'는 코드를 모르는 분도 읽을 수 있게 씁니다. 그 외는 개발자와 AI를 위한 상세입니다.

<!-- Section ownership (see CLAUDE.md conventions): 목적과 배경 / 동작 방식 / 의도적 범위 제외 are rewritten only by explainer; 요구사항 is appended only by requirements-interview; 결정 기록 / 엣지케이스와 제약 / 열린 질문 are append-only for every skill; 변경 이력 is written by work-report after the user passes the quiz. A skill creating this file keeps every heading, fills only its own sections, and leaves the rest empty — empty sections are not placeholders. Non-developer sections: one fact per sentence, ≤25 어절, plain Korean first with the term in parentheses, no arrows or code syntax. -->

## 목적과 배경

(이 단위가 왜 있는지 2–4문장)

## 요구사항

1. (확정된 항목. 근거가 된 답변이나 출처를 인용)

## 동작 방식

(무슨 일이 어떤 순서로 일어나는지, 코드 모양이 아니라 사용자 쪽에서 본 흐름)

## 결정 기록

<!-- One row per line, date first — other skills grep these rows across the area to avoid re-asking. Never delete a row; a reversal is a new row citing the old one. 결정 주체: 사용자 | 자체 | 자체(확인 필요). -->

| 날짜 | 결정 | 근거 | 기각한 대안 | 결정 주체 |
|---|---|---|---|---|

## 엣지케이스와 제약

| 상황 | 처리 | 근거 |
|---|---|---|

## 의도적 범위 제외

- (일부러 하지 않는 것과 그 이유. 절대 비워두지 말 것. 뺀 것이 없다면 이번 범위가 전부인 이유를 쓴다)

## 열린 질문

| 질문 | 해소 계획 | 재방문 시점 |
|---|---|---|

## 변경 이력

<!-- Appended by work-report only after the user confirms passing docs/quiz.html. When the file nears its 200-line cap, trim the oldest rows here first — git keeps them. -->

| 날짜 | 변경 요약 | 기준 커밋 | 검증 | 퀴즈 |
|---|---|---|---|---|
```

`skills/work-report/templates/notes.md`:

```markdown
# [주제] 작업 노트

- 시작일: YYYY-MM-DD
- 대상 spec: (docs/<영역>/specs/<단위>.md — 두 영역이면 둘 다)
- 처리: 인수(퀴즈 통과 확인) 시 work-report가 항목을 spec으로 옮기고 이 파일을 지운다

<!-- Append one entry per decision, in the format below, at decision time. Never reconstruct after the fact. Never open the spec while implementing — this file is the only write target of notes mode. -->

## YYYY-MM-DD HH:MM — [결정 제목]

- 결정:
- 이유:
- 검토한 대안:
- 보수적 선택 여부: 예/아니오 (예라면 무엇을 미뤘는지)
- 계획과의 이탈: 없음 | (있다면 spec 요구사항·동작 방식의 어디에서 벗어났는지)
- 사용자 확인 필요: 아니오 | 예 (다음 체크포인트에서 물을 질문)
- 반영 대상: (spec 경로 · 섹션 — 결정 기록 | 엣지케이스와 제약 | 의도적 범위 제외 | 동작 방식, 또는 rules 불변 규칙)
```

- [ ] **Step 4: quiz.html에 meta 줄 추가**

`skills/work-report/templates/quiz.html`에서 두 곳을 고친다.

`.explain { ... }` CSS 줄 바로 뒤에 추가:

```css
  .meta { color: #666; font-size: .9rem; margin: -.5rem 0 1rem; }
```

`<h1>머지 전 퀴즈: [주제]</h1>` 줄 바로 뒤에 추가:

```html
<p class="meta"><!-- META: work-report fills "대상: docs/<영역>/specs/<단위>.md · 기준: <commit>". Keep it here, outside the summary block, which must stay free of hashes. --></p>
```

- [ ] **Step 5: 통과 확인**

Run: `bash test/check.sh`
Expected: `OK: all checks passed`.

추가 확인: `ls skills/*/templates/` 출력이 정확히 `blindspot-pass/templates: map.md rules.md`, `explainer/templates: spec.md`, `work-report/templates: notes.md quiz.html`.

- [ ] **Step 6: Commit**

```bash
git add -A skills/*/templates test/check.sh
git commit -m "feat: replace per-cycle deliverable templates with tier templates (rules/map/spec) and a notes template"
```

---
### Task 3: 에이전트 4개 — 계층 입력, 반영 계층 출력, 계층 위치 검사, 문서 갱신 필요

**Files:**
- Modify: `agents/codebase-scanner.md`, `agents/domain-researcher.md`, `agents/doc-verifier.md`, `agents/change-analyzer.md` (전체 교체). `agents/check-runner.md`는 손대지 않는다.

**Interfaces:**
- Consumes: 없음 (스킬이 넘길 경로 규약만 전제 — `rules.md`, `map.md`, `specs/<unit>.md`, 위치 glob)
- Produces: codebase-scanner 렌즈 5개(`structure` 추가)와 발견마다 `반영 계층:` 줄. domain-researcher 발견마다 `반영 계층:` 줄. doc-verifier 입력 "채운 섹션 목록"과 검사 5 `계층`. change-analyzer 입력(spec 경로들 + map 경로 + 선택 계획 문서)과 출력 섹션 `### 문서 갱신 필요`. 스킬(Task 4–7)이 이 이름들을 그대로 쓴다.

- [ ] **Step 1: 확인용 grep을 먼저 적어 실패를 본다**

Run:
```bash
grep -c '반영 계층' agents/codebase-scanner.md agents/domain-researcher.md; grep -c '문서 갱신 필요' agents/change-analyzer.md; grep -c '계층' agents/doc-verifier.md; grep -c '`structure`' agents/codebase-scanner.md
```
Expected: 모두 `0` (grep -c는 0이면 exit 1을 내지만 숫자는 출력된다).

- [ ] **Step 2: codebase-scanner.md 전체 교체**

```markdown
---
name: codebase-scanner
description: Read-only codebase explorer. Spawned by blindspot skills with ONE assigned lens (structure, conventions, similar-features, integration-points, or edge-cases), a task description, and optionally the area's tier documents; returns structured findings with file:line evidence and a target tier per finding, so exploration never pollutes the main context.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a read-only codebase scanner. You receive ONE lens and a task description, and optionally tier document paths (`rules.md`, `map.md`, relevant `specs/*.md`) plus 위치 globs of the units in scope. Explore the repository through that lens only and return structured findings.

## Lenses

- `structure` — module inventory: each unit of this area, its responsibility, its location (used at bootstrap and map refresh)
- `conventions` — naming, layering, error handling, logging, test patterns this codebase already follows
- `similar-features` — prior art: how comparable features were built here, which files they touched, what they reused
- `integration-points` — everything the described change must touch or that touches it: APIs, schemas, configs, build, CI
- `edge-cases` — failure modes, concurrency, permissions, platform quirks, external constraints relevant to the task

## Rules

- READ-ONLY. Never create, edit, or delete files. Bash is for read-only commands only (git log/show/diff, ls, wc, find).
- If tier documents were given, read them FIRST. Report only what they do not already state, or what contradicts them — cite the row you are correcting. When 위치 globs were given, keep the search inside them.
- Every finding must cite evidence as `path:line` (or `path` for whole-file facts). No evidence, no finding.
- Prefer depth over breadth: 3–8 solid findings beat 20 shallow ones.
- If the repo has no code relevant to your lens, say so explicitly — that is itself a finding.

## Output format (your final message, in Korean)

### 스캔 결과: <lens>

- **[F1] <발견 제목>**
  - 근거: `path:line`
  - 내용: <무엇을 발견했는지 1–3문장>
  - 반영 계층: rules | map | spec(<단위>) | 없음
  - 결정 필요: <이 발견이 요구하는 구체적 질문, 없으면 "없음">

(F2, F3, ... 반복)

### 렌즈 총평

<이 렌즈에서 본 위험도와 확신도, 2–3문장>
```

- [ ] **Step 3: domain-researcher.md 전체 교체**

```markdown
---
name: domain-researcher
description: Read-only domain knowledge researcher. Spawned by blindspot-pass when the task needs knowledge that lives outside the codebase; researches the topic on the web and returns Korean findings — core concepts as glossary-ready definitions, quality criteria, pitfalls, and decisions — each cited with a source URL and tagged with the tier it belongs in.
tools: WebSearch, WebFetch
model: sonnet
---

You are a read-only domain researcher. You receive a domain topic, a task description, and what the user already knows (including the 용어 rows already in the area's `rules.md`). Research the domain and return distilled findings that convert the user's unknown unknowns into concrete decisions.

## Focus

- Core concepts — the minimum vocabulary needed to discuss the task ("what is X"), each as a one-sentence definition that can be pasted into a 용어 table
- Quality criteria — what "good" looks like in this domain, how practitioners judge results (these become acceptance criteria in the spec)
- Pitfalls — common beginner mistakes and failure modes relevant to the task
- Decisions — choices the user will face during the task, with the realistic options

## Rules

- READ-ONLY web research. Never create, edit, or delete files.
- Every finding cites a source URL. If web access is unavailable, label it `출처: 모델 지식 (웹 접근 불가)` instead — never fabricate URLs.
- Distill; never dump raw article text. 3–8 solid findings beat 20 shallow ones.
- Skip what the user already knows (given in your input) — depth over re-explanation.

## Output format (your final message, in Korean)

### 도메인 리서치: <topic>

#### 핵심 개념 (교육용 최소 어휘)

- **<개념>**: <한 문장 정의> — 출처: <URL>

#### 발견

- **[D1] <발견 제목>**
  - 출처: <URL>
  - 내용: <무엇을 알아야 하는지 1–3문장>
  - 반영 계층: rules 용어 | spec 요구사항 | spec 결정 기록 | spec 엣지케이스와 제약 | 없음
  - 결정 필요: <이 발견이 요구하는 구체적 질문, 없으면 "없음">

(D2, D3, ... 반복)

### 총평

<이 도메인에서 사용자가 가장 크게 다칠 수 있는 지점과 확신도, 2–3문장>
```

- [ ] **Step 4: doc-verifier.md 전체 교체**

```markdown
---
name: doc-verifier
description: Read-only document verifier. Spawned by requirements-interview, blindspot-pass, explainer, and work-report (report mode) after a tier document is written or edited (the quiz is gated by docs_check.py instead); checks the given file for placeholders, internal contradictions, ambiguous statements, scope creep, and content sitting at the wrong tier, returning PASS or a numbered Korean issue list.
tools: Read, Grep, Glob
model: haiku
---

You are a document verifier. You receive one file path, and optionally the list of sections the calling skill filled in this pass. Read the file and check exactly five things:

1. **Placeholders** — TBD, TODO, 미정, template text left unfilled (e.g. `[주제]`, `YYYY-MM-DD` literals). In tier documents (`rules.md`, `map.md`, `specs/*.md`) an empty section, the cell value `없음` or `해당 없음`, and a section the caller did not name as filled are NOT placeholders — living documents fill up over several cycles. When a filled-section list was given, check placeholders only inside those sections.
2. **Contradictions** — statements in one section that conflict with another
3. **Ambiguity** — any requirement or decision readable in two different ways
4. **Scope** — content beyond the document's stated purpose, or a purpose too broad for one document
5. **Tier fit** (tier documents only) — content that belongs at another tier: an area-wide invariant inside a spec, a single-unit edge case inside `map.md`, a module inventory inside `rules.md`, or per-cycle process residue (interview transcripts, raw scan output) anywhere. Name the target tier. Report only clear cases.

## Rules

- READ-ONLY. Report; never fix.
- Judge only the document (and files it explicitly links, if needed for contradiction checks). Do not review code quality. Link integrity between a map and its spec files is checked by `docs_check.py`, not by you.
- Be strict about placeholders in filled sections, lenient about style.

## Output format (your final message, in Korean)

If clean:

PASS — 지적사항 없음

Otherwise:

1. [심각도: 높음|중간|낮음] [유형: 미기입|모순|모호성|범위|계층] <섹션명>: <문제> → 제안: <수정 방향>
2. ...
```

- [ ] **Step 5: change-analyzer.md 전체 교체**

```markdown
---
name: change-analyzer
description: Read-only git diff analyst. Spawned by work-report (report mode) with a base ref, the touched Tier 3 spec paths and the area map; analyzes changes between the base and HEAD and returns a structured Korean summary with per-file changes, risk spots, deviations from the spec (and from a plan document when one is given), documentation rows the diff makes stale, test coverage presence, and quiz question candidates.
tools: Read, Grep, Glob, Bash
---

You are a git change analyst. You receive a base ref (if none given, use `git merge-base main HEAD`, falling back to `master` when `main` does not exist; if both fail, use the first commit). You also receive the Tier 3 spec paths of the touched units and the area's `map.md` path, and optionally a plan document path.

## Procedure

1. `git diff --stat <base>...HEAD` for the shape of the change
2. `git diff <base>...HEAD` and `git log --oneline <base>..HEAD` for content
3. Read changed files where the diff alone is unclear
4. Read the given specs (their 요구사항 and 동작 방식 are the plan) and the plan document if any; note where the diff deviates from them (scope, approach, behavior)
5. Match every changed code file against the 위치 column of the map's 단위 table; collect files that match no unit, units whose 위치 no longer exists, and rows the diff makes stale (map 통합 지점, `rules.md` 불변 규칙, spec 동작 방식 / 엣지케이스와 제약)
6. Check whether tests covering the changed behavior exist (look for test files touching the changed modules)

## Rules

- READ-ONLY. Bash is for read-only git/inspection commands only.
- Cite `path:line` for every risk spot.
- Risk spots include suspected defects in the diff (logic errors, unhandled edge cases) — mark those 의심 결함. Edits under `docs/` are never risk spots.
- Quiz candidates must target behavior and risk, never trivia (no "how many files changed").

## Output format (your final message, in Korean)

### 변경 요약

<2–4문장>

### 파일별 핵심 변경

| 파일 | 핵심 변경 |
|---|---|

### 위험 지점

- `path:line` — <왜 위험한지>

### 계획 대비 이탈

- <spec의 요구사항·동작 방식(또는 계획 문서)과 다르게 구현되거나 빠진 점> — `path:line`

### 문서 갱신 필요

- `<계층 파일> · <섹션>` — <반영할 내용> (어느 단위 위치에도 맞지 않는 파일, 사라진 위치, 바뀐 통합 지점·불변 규칙·동작 포함. 없으면 "없음")

### 테스트

<변경 동작을 덮는 테스트 유무와 위치>

### 퀴즈 후보 (4–6개)

1. <리뷰어가 반드시 이해해야 할 포인트를 묻는 질문> — 정답: <요지>
```

- [ ] **Step 6: 통과 확인**

Run: Step 1의 grep을 다시 실행하고 `bash test/check.sh`.
Expected: grep 결과가 모두 1 이상. `OK: all checks passed`. `agents/check-runner.md`는 `git diff --stat`에 나오지 않는다.

- [ ] **Step 7: Commit**

```bash
git add agents/
git commit -m "feat: agents read tier documents, tag findings with a target tier, and report stale documentation rows"
```

---
### Task 4: requirements-interview SKILL.md 재작성

**Files:**
- Modify: `skills/requirements-interview/SKILL.md` (전체 교체)

**Interfaces:**
- Consumes: Task 2의 `spec.md` 헤딩(요구사항, 결정 기록, 열린 질문, 목적과 배경), Task 3의 codebase-scanner 입력 규약(계층 경로 + 위치 glob), doc-verifier "채운 섹션 목록", Task 1의 `docs_check.py`
- Produces: 결정 기록 행 형식 `| YYYY-MM-DD | 결정 | 근거 | 기각한 대안 | 사용자 |` (한 줄, 날짜 시작). 다른 스킬은 `grep -h '^| 20' docs/<area>/specs/*.md`로 이 행을 읽는다.

- [ ] **Step 1: 확인용 grep으로 현재 상태를 본다**

Run: `grep -c 'docs/blindspot' skills/requirements-interview/SKILL.md; grep -c '25 어절' skills/requirements-interview/SKILL.md`
Expected: 첫 줄 `4` 이상(옛 경로가 있음), 둘째 줄 `1` 이상.

- [ ] **Step 2: 전체 교체**

```markdown
---
name: requirements-interview
description: Use when the user starts discussing a new feature, change request, or any task with unclear requirements — runs a structured Korean interview (one question at a time, architecture-changing questions first) grounded in the area's rules, map, and recorded decisions, then writes the confirmed requirements and decisions into the unit's Tier 3 spec.
---

# Requirements Interview

The user's first prompt is a lossy map of what they actually need. Recover the territory by interviewing before building.

## Workflow

0. **Locate the tiers.** Decide which area the request touches (paths the user names; the areas present as `docs/*/map.md`). Read that area's `docs/<area>/rules.md` and the 단위 table of `docs/<area>/map.md`. If the area has no `map.md`, tell the user (Korean) that the area is not bootstrapped and offer `blindspot-pass`; if they decline, continue on a live scan and write only the spec.

1. **Classify first.** Sort what you know into the four quadrants (in your head — the table is not written anywhere):
   - Known Knowns — explicitly stated in the request
   - Known Unknowns — questions you already know need answers
   - Unknown Knowns — preferences the user likely holds but hasn't said (naming, style, existing patterns)
   - Unknown Unknowns — territory nobody has looked at; note candidates, leave the digging to `blindspot-pass`

2. **Ground before asking.** Pick the unit(s) the request touches from the 단위 table and read their `docs/<area>/specs/<unit>.md` if they exist. Collect past decisions across the whole area without opening every spec: `grep -h '^| 20' docs/<area>/specs/*.md` returns the one-line 결정 기록 rows. Then spawn ONE `codebase-scanner` agent (subagent_type: `codebase-scanner`) with lens `conventions`, the task description, the `rules.md` and `map.md` paths, and the 위치 globs of the touched units, so it reports only what the tiers do not already say. Questions that ignore the actual code waste the user's time. Skip the scanner only if the project has no code yet.

3. **Interview.** In Korean, ONE question per message, via AskUserQuestion with 2–4 concrete options where possible.
   - Write every question and option for someone who has never seen the code: unavoidable technical terms plain Korean first with the term in parentheses; code identifiers only after a plain description of what they do. One fact per sentence, ≤25 어절 each.
   - Order by architecture impact: answers that change the design come first.
   - Never re-ask what a `rules.md` row or a 결정 기록 row already answers — cite the row and move on.
   - Stop when remaining answers would no longer change what you'd build (typically 3–6 questions).
   - Keep every question, answer, and its architecture impact — they become 결정 기록 rows.

4. **Write into the spec.** Target `docs/<area>/specs/<unit>.md` of the primary unit — the unit whose 위치 covers most of the files the work will touch. A feature that adds a module is a new unit: add its row to the map's 단위 table with 상세 명세 `specs/<unit>.md`. If the spec does not exist, create it from the `explainer` skill's `templates/spec.md` (`.claude/skills/explainer/templates/spec.md` in consumer projects) with every heading present and 상태 초안, then fill only your sections:
   - 요구사항 — numbered, each item citing the answer that confirmed it
   - 결정 기록 — one row per answered question, one line each: 날짜 | 결정 | 근거 (the user's answer) | 기각한 대안 | 사용자
   - 열린 질문 — remaining Known Unknowns, plus Unknown Unknown candidates with 해소 계획 "blindspot-pass에서 점검"
   - 목적과 배경 — a 2–3 sentence draft only if it is empty; explainer owns it
   An answer that binds the whole area (a convention, a prohibition) also becomes a 불변 규칙 row in `rules.md`. Never touch sections another skill owns; append rows at the end of tables.
   Write for a reader who has never seen the code: no arrow shorthand (A→B) or unexplained jargon; unavoidable technical terms plain Korean first with the term in parentheses; one fact per sentence, ≤25 어절 each — split long compound sentences. 근거 cells keep their technical form. Before saving, self-check every sentence in 요구사항 and every 결정 cell: could someone who has never seen code follow it, and is it one fact within 25 어절? Update 최종 갱신 on every file you edited.

5. **Verify.** Spawn `doc-verifier` (subagent_type: `doc-verifier`) on the spec, naming the sections you filled (요구사항, 결정 기록, 열린 질문). Fix every reported issue, re-save. Then run `python3 .claude/skills/work-report/scripts/docs_check.py <spec path>` (the `work-report` skill's `scripts/docs_check.py`) and fix every violation. Do not skip on PASS-looking drafts — verification is not optional.

6. **Hand off.** Tell the user (Korean): 다음 단계는 `blindspot-pass`로 Unknown Unknowns를 구체화하는 것.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries — correct a stale entry's referent instead. -->
- Never ask the user something answerable by reading the code — that is what the scanner run is for.
- One decision per question. Batched questions get half-answers.
- A question the user cannot parse gets a guessed answer; guessed answers become wrong requirements. Every question and every document sentence must survive the "reader has never seen the code" test.
- Clean vocabulary does not equal readable: a 40+ 어절 sentence with nested clauses locks out the same readers even with zero jargon — the one-fact / ≤25 어절 bar is part of the standard.
- A question the user answered in a past cycle wastes the budget twice — past decisions live in the 결정 기록 rows across the area's specs; grep them so the interview can cite instead of re-ask.
- Reading every spec in the area "to be safe" is the old pile under a new name — the 단위 table says which specs the task touches; the grep covers the rest.
```

- [ ] **Step 3: 통과 확인**

Run: `grep -c 'docs/blindspot' skills/requirements-interview/SKILL.md; grep -c '25 어절' skills/requirements-interview/SKILL.md; bash test/check.sh`
Expected: `0`, `1` 이상, `OK: all checks passed`.

- [ ] **Step 4: Commit**

```bash
git add skills/requirements-interview/SKILL.md
git commit -m "feat: requirements-interview writes requirements and decisions into the unit spec, greps area decisions instead of scanning history"
```

---

### Task 5: blindspot-pass SKILL.md 재작성 (부트스트랩 포함)

**Files:**
- Modify: `skills/blindspot-pass/SKILL.md` (전체 교체)

**Interfaces:**
- Consumes: Task 2의 `rules.md`·`map.md`·`spec.md` 헤딩, Task 3의 렌즈 `structure`와 `반영 계층` 줄, doc-verifier "채운 섹션 목록", Task 1의 `docs_check.py`
- Produces: 부트스트랩 절차(다른 스킬은 "map.md가 없으면 blindspot-pass를 제안"만 한다), 렌즈→목적지 표

- [ ] **Step 1: 현재 상태 확인**

Run: `grep -c 'docs/blindspot' skills/blindspot-pass/SKILL.md; grep -c '25 어절' skills/blindspot-pass/SKILL.md`
Expected: `3` 이상, `1` 이상.

- [ ] **Step 2: 전체 교체**

```markdown
---
name: blindspot-pass
description: Use when starting work in an unfamiliar codebase or domain, before writing an implementation plan, when the user asks what they might be missing ("내가 모르는 게 뭐지"), or when an area has no docs/<area>/map.md yet or the user asks to refresh the map — fans out parallel codebase-scanner agents (plus a domain-researcher for knowledge outside the codebase), converts unknown unknowns into concrete decidable questions, resolves them with the user, and files every finding into the area's rules, map, or unit spec.
---

# Blindspot Pass

Unknown unknowns are the failures you don't see coming. Concretize them into decidable questions before they become rework — and leave the tiers better than you found them.

## Workflow

0. **Bootstrap or refresh (only when needed).** Run this step when the touched area has no `docs/<area>/map.md`, or when the user asks for a map refresh with no feature attached.
   - Decide the areas from evidence. Existing `docs/*/map.md` win. Otherwise look at most two directory levels deep: a directory named `frontend`, `web`, `client`, `ui`, `app`, or `apps/*` holding a UI manifest (package.json depending on react, vue, svelte, next, nuxt, or angular; or index.html with src/) → `frontend`; a directory named `backend`, `server`, `api`, `service`, or `services/*`, or a server manifest (go.mod, pom.xml, build.gradle*, Cargo.toml, pyproject/requirements with django, fastapi, or flask, Gemfile, composer.json, *.csproj, mix.exs, package.json depending on express, fastify, nest, hono, or koa) → `backend`. Distinct matches → both areas; one match → that one; the same directory matching both, or nothing → one area named `core`. State the result in Korean. Ask ONE AskUserQuestion with the candidates only when the evidence genuinely conflicts.
   - Spawn `codebase-scanner` agents IN PARALLEL (subagent_type: `codebase-scanner`), per area, lenses `structure`, `conventions`, `integration-points`, `edge-cases` — each with the area root and this task's description, and the existing tier paths when refreshing. At most 8 agents per call; with more than two areas, bootstrap only the areas this task touches.
   - Create `docs/<area>/rules.md` and `docs/<area>/map.md` from `templates/rules.md` and `templates/map.md` in this skill's folder and fill them: structure → 단위 table with 상세 명세 `없음` on every row (never create specs here); conventions → 불변 규칙 and 관례; integration-points → 통합 지점; edge-cases → 알려진 위험 (only risks spanning two or more units); discovered test/lint/build commands → 표준 명령. A refresh edits rows in place.
   - Carry these findings straight into step 3. Do not fan out again in step 2 for the same task.

1. **Collect input and classify territory.** The task description, `docs/<area>/rules.md`, the 단위 table of `docs/<area>/map.md`, the specs of the units the task touches, and the area's decision rows (`grep -h '^| 20' docs/<area>/specs/*.md`) — do not re-ask what they already answer. Split the unfamiliarity into two territories: code (this repository) and domain (knowledge living outside the codebase — e.g. color grading, payment standards). A task can have both.

2. **Fan out scanners.** Spawn `codebase-scanner` agents IN PARALLEL (one message, multiple Agent calls, subagent_type: `codebase-scanner`), one per lens:
   - `conventions`
   - `similar-features`
   - `integration-points`
   - `edge-cases`
   Each agent receives: its lens, the task description, the `rules.md` and `map.md` paths, the touched specs' paths, and the 위치 globs of the touched units — with the instruction to report only what those documents do not already state, cite any row it contradicts, and tag every finding with its 반영 계층. Use 3 lenses (drop `similar-features`) when the project is greenfield; skip the codebase lenses entirely only when the task touches no code.

   If domain territory exists, add ONE `domain-researcher` agent (subagent_type: `domain-researcher`) to the same parallel batch, with: the domain topic, the task description, and what the user already knows (including the 용어 rows already in `rules.md`).

3. **Synthesize.** Merge findings yourself (plain reasoning, no extra agent). For each finding: restate it as a concrete, decidable question ("X를 어떻게 할지", not "X 주의") written for someone who has never seen the code — unavoidable technical terms plain Korean first with the term in parentheses, code identifiers only after a plain description, one fact per sentence, ≤25 어절 each. Assign a quadrant, sort by architecture impact. Keep evidence attached — `file:line` for code findings, source URL for domain findings; evidence stays technical.

4. **Resolve with the user.** Present questions in Korean via AskUserQuestion, architecture-changing first. Questions, options, and the primer follow the same non-developer bar as step 3. If domain findings exist, open with a short primer (5–10 lines in Korean, from the researcher's 핵심 개념, short sentences with an everyday comparison for each abstract concept) — the user must understand the concepts to answer the questions. Questions the findings already answer: decide yourself and record them as 결정 기록 rows with 결정 주체 자체 and the evidence as 근거. If more than 7 questions remain after self-resolution, do not present them all — the count signals thin evidence, so spawn follow-up `codebase-scanner` / `domain-researcher` agents targeted at the weakest-evidence clusters and self-resolve again. Each follow-up agent receives the prior findings for its cluster so it extends, not repeats, the exploration. Present at most the 7 highest architecture-impact questions; move the rest to the spec's 열린 질문 with a 재방문 시점.

5. **File the findings.** There is no unknowns document — every finding goes to the tier where it will be read next, or is dropped:

   | Finding | Destination |
   |---|---|
   | convention, prohibition, area-wide invariant | `rules.md` 불변 규칙 / 관례 |
   | new or moved unit, a flow | `map.md` 단위 / 주요 흐름 |
   | integration point | `map.md` 통합 지점 |
   | risk spanning two or more units | `map.md` 알려진 위험 |
   | single-unit failure mode or constraint | spec 엣지케이스와 제약 |
   | prior art from `similar-features` | cited in the 근거 cell of the decision it informs; a reuse rule → `rules.md` 관례 |
   | domain 핵심 개념 used by two or more units | `rules.md` 용어, with 출처 |
   | domain 품질 기준 | spec 요구사항 as acceptance criteria, with 출처 |
   | question resolved by the user or self-resolved | spec 결정 기록: 날짜 \| 결정 \| 근거 \| 기각한 대안 \| 사용자 or 자체 — one line per row |
   | question parked | spec 열린 질문 with 재방문 시점 |
   | fits nowhere | dropped — never archive raw scan output anywhere |

   A spec that does not exist yet is created from the `explainer` skill's `templates/spec.md` (`.claude/skills/explainer/templates/spec.md` in consumer projects) with every heading present and 상태 초안; fill only the sections above. Append rows at the end of tables; never rewrite rows other skills wrote. The 결정, 질문, and 규칙 cells are read by non-developers — apply the step 3 sentence bar to them; before saving, self-check every sentence in those cells: could someone who has never seen code follow it, and is it one fact within 25 어절? The 근거 cells are technical evidence for later stages — technical language is correct there; do not simplify it. Update 최종 갱신 on every file you edited.

6. **Verify.** For every file you edited, spawn `doc-verifier` (subagent_type: `doc-verifier`) naming the sections you filled; fix every issue, re-save. Then run `python3 .claude/skills/work-report/scripts/docs_check.py <every edited file>` (the `work-report` skill's `scripts/docs_check.py`) and fix every violation — over the line cap means content sits at the wrong tier: move it down, never raise the cap.

7. **Hand off.** Tell the user (Korean): 설계 문서가 필요하면 `explainer`, 바로 구현이면 `work-report` 노트 모드로.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries — correct a stale entry's referent instead. -->
- Scanners return findings; YOU convert them to questions. A finding without a decision attached is noise.
- Do not serialize the scanner spawns — parallel or it takes 4x longer.
- Domain unknowns don't live in the repo — codebase lenses on a pure-domain task return empty findings. Classify territory first; route domain topics to `domain-researcher`.
- A concretized question the user cannot parse defeats the whole pass — the decision gets guessed, not made. Questions and decisions in plain Korean; 근거 cells stay technical, and there is no raw scan summary any more — a finding that files nowhere is dropped, not archived.
- Clean vocabulary does not equal readable: a 40+ 어절 sentence with nested clauses locks out the same readers even with zero jargon — the one-fact / ≤25 어절 bar is part of the standard.
- A long question list is an analysis failure, not thoroughness: past ~7, answer quality collapses and guessed answers become fake requirements. The cap triggers more scanning, never more asking.
- The urge to keep "just the raw findings somewhere" is the old unknowns file coming back — the tiers are the only durable output.
- Bootstrap builds Tier 1 and 2 only. A spec per map row is N files of speculative content; specs appear when work touches a unit.
```

- [ ] **Step 3: 통과 확인**

Run: `grep -c 'docs/blindspot' skills/blindspot-pass/SKILL.md; grep -c '25 어절' skills/blindspot-pass/SKILL.md; bash test/check.sh`
Expected: `0`, `1` 이상, `OK: all checks passed`.

- [ ] **Step 4: Commit**

```bash
git add skills/blindspot-pass/SKILL.md
git commit -m "feat: blindspot-pass bootstraps tier 1/2, files findings by lens into rules/map/spec, drops the unknowns document"
```

---
### Task 6: explainer SKILL.md 재작성

**Files:**
- Modify: `skills/explainer/SKILL.md` (전체 교체)

**Interfaces:**
- Consumes: Task 2의 `spec.md`(이 스킬 소유), `map.md` 헤딩(단위, 주요 흐름, 통합 지점), Task 3의 codebase-scanner 입력 규약, doc-verifier "채운 섹션 목록", Task 1의 `docs_check.py`
- Produces: spec의 목적과 배경·동작 방식·의도적 범위 제외를 고쳐 쓰는 유일한 스킬 (work-report는 구현대로 정정하거나 덧붙이기만 한다, 스펙 §4.3). 상태를 `확정`으로 바꾸는 유일한 스킬.

- [ ] **Step 1: 현재 상태 확인**

Run: `grep -c 'docs/blindspot' skills/explainer/SKILL.md; grep -c '25 어절' skills/explainer/SKILL.md`
Expected: `2` 이상, `1` 이상.

- [ ] **Step 2: 전체 교체**

```markdown
---
name: explainer
description: Use when the user asks for a spec, design document, explainer, pitch, or "문서로 정리해줘" — completes the unit's Tier 3 spec (purpose, behavior, alternatives with trade-offs, explicit out-of-scope items) from the recorded requirements, decisions, and code reality, and updates the area map, so a zero-context reader can understand what is being built and why.
---

# Explainer

One spec a zero-context reader can use to understand what a unit does, what was decided, and what was deliberately left out.

## Workflow

1. **Gather inputs.** Read `docs/<area>/rules.md`, `docs/<area>/map.md`, and `docs/<area>/specs/<unit>.md` for every unit the topic touches; skim the code their 위치 columns name. If the touched spec has neither 요구사항 nor 결정 기록 rows, tell the user and recommend `requirements-interview` or `blindspot-pass` first — never fabricate requirements. Create a spec from `templates/spec.md` in this skill's folder only when the user explicitly says there is nothing to interview.

2. **Write your sections.** You own 목적과 배경, 동작 방식, and 의도적 범위 제외 — rewrite them freely, but keep the as-built corrections and additions work-report appended to 동작 방식 and 의도적 범위 제외 (fold them into your prose; never drop them). In 결정 기록, fill empty 기각한 대안 cells and append new rows (one line each, date first); never edit rows other skills wrote. In 열린 질문, give every row a 해소 계획 or an owner. Do not touch 요구사항. Then update `map.md`: the unit's 단위 row (add it with 상세 명세 `specs/<unit>.md` when the unit is new) and a 주요 흐름 row for the behavior you described; append at the end of tables.
   The non-developer sections (목적과 배경, 동작 방식, 의도적 범위 제외) are for a reader who has never seen the code:
   - Describe what happens and why, never how the code looks. No arrow shorthand (A→B), no unexplained jargon; unavoidable technical terms plain Korean first with the term in parentheses — e.g. "설정 파일이 깨져 있으면(잘못된 JSON)".
   - One fact per sentence, ≤25 어절 each — split long compound sentences. Name concrete actors and actions ("사용자가 저장을 누르면"); on first appearance of an abstract concept, add one everyday example or comparison.
   - Code identifiers and file paths appear only where they are the subject being explained, introduced by a plain description.
   - Before saving, self-check every sentence: could someone who has never seen code follow it, and is it one fact within 25 어절? If not, rewrite it.

   The rules that matter most:
   - every real decision in 결정 기록 shows at least one rejected alternative and why
   - 의도적 범위 제외 — mandatory and never empty; if truly nothing was cut, state why the scope is total
   - 열린 질문 — each unresolved item gets an owner or a resolution plan

3. **Save** in place: set 상태 to 확정 and 최종 갱신 to today on the spec; update 최종 갱신 on the map.

4. **Verify.** Spawn IN PARALLEL (one message, two Agent calls): `doc-verifier` (subagent_type: `doc-verifier`) on the spec naming the sections you filled, and `codebase-scanner` (subagent_type: `codebase-scanner`) with lens `integration-points`, the spec and map paths, and instructions to cross-check them against code reality — every integration point the spec assumes, every 통합 지점 row, and every 위치 glob of the touched units must exist and match, mismatches cited as `file:line`. Fix every issue from both (correct map rows too), re-save. Then run `python3 .claude/skills/work-report/scripts/docs_check.py <spec> <map>` (the `work-report` skill's `scripts/docs_check.py`) and fix every violation. Skip the cross-check only when the project has no code.

5. **Hand off.** Tell the user (Korean): 구현 시작 시 `work-report` 노트 모드로.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries — correct a stale entry's referent instead. -->
- A spec is not a concatenation of interview answers and scan output; its 목적과 배경 and 동작 방식 must stand alone for a reader with zero context.
- A spec that reads like an engineering changelog fails its zero-context purpose; every sentence in the non-developer sections must survive the "reader has never seen the code" test.
- Clean vocabulary does not equal readable: a 40+ 어절 sentence with nested clauses locks out the same readers even with zero jargon — the one-fact / ≤25 어절 bar is part of the standard.
- Rewriting 요구사항 or another skill's 결정 기록 rows "for consistency" destroys the record the never-re-ask rule depends on — append, never rewrite.
- A spec created without an interview is fiction with headings; refuse unless the user says there is nothing to ask.
```

- [ ] **Step 3: 통과 확인**

Run: `grep -c 'docs/blindspot' skills/explainer/SKILL.md; grep -c '25 어절' skills/explainer/SKILL.md; bash test/check.sh`
Expected: `0`, `1` 이상, `OK: all checks passed`.

- [ ] **Step 4: Commit**

```bash
git add skills/explainer/SKILL.md
git commit -m "feat: explainer completes the unit spec in place and updates the area map instead of writing a dated document"
```

---

### Task 7: work-report SKILL.md 재작성

**Files:**
- Modify: `skills/work-report/SKILL.md` (전체 교체)

**Interfaces:**
- Consumes: Task 2의 `notes.md`·`quiz.html`(이 스킬 소유), `spec.md` 헤딩, Task 3의 change-analyzer 입력·`문서 갱신 필요` 출력, doc-verifier "채운 섹션 목록", Task 1의 `docs_check.py`
- Produces: `docs/notes/<slug>.md`, `docs/quiz.html`, spec 변경 이력 행 `| 날짜 | 변경 요약 | 기준 커밋 | 검증 | 퀴즈 |`

- [ ] **Step 1: 현재 상태 확인**

Run: `grep -c 'docs/blindspot' skills/work-report/SKILL.md; grep -c 'quiz_check.py' skills/work-report/SKILL.md; grep -c '25 어절' skills/work-report/SKILL.md`
Expected: `4` 이상, `2` 이상, `1` 이상.

- [ ] **Step 2: 전체 교체**

```markdown
---
name: work-report
description: "Use in two modes — (a) notes mode the moment implementation starts and whenever a non-obvious decision or plan deviation happens mid-work: append it to docs/notes/<slug>.md immediately; (b) report mode when work completes or before merge: analyze the diff via change-analyzer, promote the notes into the touched specs and map, and generate docs/quiz.html, the self-contained pre-merge quiz the user must pass before merging."
---

# Work Report

The work is territory; the tiers are the map you hand back. Keep the map honest while memory is fresh — never reconstructed at the end.

## Notes mode

Trigger: implementation starts, OR you make a non-obvious decision, pick a conservative option on an unexpected edge case, or deviate from the plan.

1. Ensure `docs/notes/<slug>.md` exists — if not, create it from `templates/notes.md` in this skill's folder, naming the target spec(s). Do not open the spec.
2. Append one Korean entry per event AT DECISION TIME (not batched later): 결정 / 이유 / 검토한 대안 / 보수적 선택 여부 / 계획과의 이탈 여부 / 사용자 확인 필요 / 반영 대상 (the spec section, or `rules.md` 불변 규칙, the entry will be promoted into).
3. A decision that seems to need user input: if it is reversible, take the conservative option, log it, and mark it 사용자 확인 필요 for the next checkpoint (stage boundary or report mode) instead of asking mid-flow. Ask immediately only when the choice is irreversible or destructive (data loss, external side effects, published contracts).
4. Continue working — notes mode never blocks implementation.

## Report mode

Trigger: work complete, pre-merge, or the user asks for a report.

1. **Analyze.** Spawn IN PARALLEL (one message, two Agent calls): `change-analyzer` (subagent_type: `change-analyzer`) with the base ref (default: merge-base with the default branch — main, else master), the touched spec paths, the area `map.md` path, and a plan document path when one exists; and `check-runner` (subagent_type: `check-runner`) with the commands from `rules.md` 표준 명령 (or the project's known checks).
2. **Ask first.** Present every 사용자 확인 필요 item queued in `docs/notes/<slug>.md` as batched Korean questions BEFORE touching any tier file — the answers change what gets promoted.
3. **Promote into the tiers.** Sources: the notes, the change-analyzer output, the check-runner 검증 결과. In the primary unit's spec (and any other spec a note's 반영 대상 names): each note becomes a 결정 기록 row (one line, date first, 결정 주체 사용자 or 자체); edge cases met during implementation go to 엣지케이스와 제약; things cut go to 의도적 범위 제외; 동작 방식 is corrected to what was actually built (adjust the affected sentences — do not rewrite explainer's prose wholesale). Apply every `문서 갱신 필요` item: 단위 rows and 위치 in `map.md`, changed 통합 지점, changed 불변 규칙 in `rules.md`. If the primary spec's 의도적 범위 제외 is still empty, fill it or state why the scope is total. Update 최종 갱신. Then, for every tier file you edited, spawn `doc-verifier` (subagent_type: `doc-verifier`) naming the sections you touched, fix every issue, and run `python3 .claude/skills/work-report/scripts/docs_check.py <every edited tier file>` (`scripts/docs_check.py` in this skill's folder).
4. **Generate the quiz.** Copy `templates/quiz.html` from this skill's folder over `docs/quiz.html` (one file, overwritten every cycle); fill the title, the meta line (target spec path and base commit — outside the summary block), the 변경 요약 block, and the `QUESTIONS` array with 4–6 Korean multiple-choice questions targeting what a reviewer must understand: 위험 지점, 동작 변화, 계획 이탈, 범위 제외. Wrong options must be plausible. The quiz reader is a non-developer — write every sentence for someone who has never seen the code:
   - Ask what happens or what could go wrong, never how the code looks. No code syntax, identifiers, file paths, or shell fragments inside question or option sentences; no arrow shorthand (A→B); no unexplained jargon.
   - Unavoidable technical terms: plain Korean first, term in parentheses — e.g. "설정 파일이 깨져 있으면(잘못된 JSON)".
   - The quiz is a self-contained gate, not an exam: the 변경 요약 plus the question's own scenario sentence must contain every fact needed to answer. Never quiz recall of process history (which step, review, or commit did what); ask the reader to apply a summary fact — what changes for users, what could go wrong, what was deliberately not done.
   - A question is one scenario sentence plus one question sentence — one fact each, ≤25 어절 per sentence. Options are complete sentences, one idea each, ≤40 Korean characters, parallel in form — a conspicuously long option must not give away the answer. Vary the correct answer's position across questions.
   - Every question gets an `explain` field: 2–3 plain Korean sentences (same ≤25 어절 bar) on why the answer is right and why the most tempting wrong option is wrong. Technical terms and file paths belong here (in parentheses), not in questions.
   - The summary block follows the same sentence rules: user-visible changes only, no commit hashes, no arrows — and it must state every fact the questions rely on.
   - Before saving, self-check every question: could someone who read only the 변경 요약 answer it? Is every sentence one fact within 25 어절, every option within 40 characters? If not, rewrite.
   - Then run the countable check: `python3 .claude/skills/work-report/scripts/docs_check.py docs/quiz.html`. Fix every reported violation before the gate.
   Also print in chat (Korean) the 3–5 sentence 사람용 요약 and the 리뷰 포인트 (파일:라인 — technical, for code reviewers); put both in the PR body when the project uses pull requests.
5. **Gate.** Tell the user (Korean): 퀴즈를 브라우저로 열어 전부 맞히기 전에는 머지하지 말 것. Never declare the work merged/done until the user confirms passing. When they confirm: append one 변경 이력 row to the primary spec (one per area when two areas were touched) — 날짜 | 변경 요약 in one sentence | 기준 커밋 | 검증 (the check-runner 총평) | 퀴즈 통과 date — and delete `docs/notes/<slug>.md`.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries — correct a stale entry's referent instead. -->
- Notes written after the fact are fiction; append at decision time.
- Quiz questions about trivia (file names, line counts) are worthless — ask about behavior and risk.
- A quiz written in the author's head-language (code syntax, arrows, compressed jargon) locks out non-developers; every sentence must survive the "reader has never seen the code" test.
- A 변경 요약 written in engineer-speak (arrows, raw jargon) locks stakeholders out — but only the summary and the spec's non-developer sections: 리뷰 포인트, 근거 cells, and 엣지케이스 처리 are technical by design; simplifying them destroys their function.
- Clean vocabulary does not equal readable: a 40+ 어절 sentence with nested clauses locks out the same readers even with zero jargon — the one-fact / ≤25 어절 bar is part of the standard.
- A quiz that needs process-history recall is an exam, not a gate; if the 변경 요약 cannot support the answer, fix the summary or drop the question.
- Stopping mid-work to ask about a reversible choice trades flow for false safety — conservative default + note + checkpoint batch keeps the decision visible without blocking. Immediate questions are reserved for irreversible or destructive choices.
- Self-check alone has let over-length sentences slip through; sentence and option length are countable, so `scripts/docs_check.py` is the enforcement — eyeballing is not.
- Opening the spec "just to check" during implementation turns notes mode into a rewrite session — notes go to `docs/notes/<slug>.md` only; the spec changes at promotion time.
- Promoting before asking the 사용자 확인 필요 batch writes guesses into shared documents every later cycle trusts — ask first, promote second.
```

- [ ] **Step 3: 통과 확인**

Run: `grep -c 'docs/blindspot' skills/work-report/SKILL.md; grep -c 'quiz_check.py' skills/work-report/SKILL.md; grep -c '25 어절' skills/work-report/SKILL.md; bash test/check.sh`
Expected: `0`, `0`, `1` 이상, `OK: all checks passed`.

- [ ] **Step 4: Commit**

```bash
git add skills/work-report/SKILL.md
git commit -m "feat: work-report keeps notes in docs/notes, promotes them into the tiers, and overwrites a single docs/quiz.html"
```

---
### Task 8: blindspot-flow SKILL.md 재작성 + 폐지 경로·참조 tripwire

**Files:**
- Modify: `skills/blindspot-flow/SKILL.md` (전체 교체), `test/check.sh` (검사 3 확장, 검사 7·10 신설)

**Interfaces:**
- Consumes: Task 4–7의 다섯 스킬이 모두 새 경로만 쓴다는 사실(검사 7이 이제야 켜지는 이유)
- Produces: 검사 7(폐지 경로 없음), 검사 10(템플릿 참조 실존), 검사 3 확장(에이전트 5개 모두 참조됨)

- [ ] **Step 1: 실패하는 검사 추가**

`test/check.sh`의 `# --- 3.` 블록 끝(`done <<<"$refs"` 뒤)에 추가한다.

```bash
for f in "$ROOT"/agents/*.md; do
  name="$(basename "$f" .md)"
  grep -q "subagent_type: \`$name\`" "$ROOT"/skills/*/SKILL.md || fail "agents/$name.md is not referenced by any SKILL.md"
done
```

검사 8 블록 뒤(마지막 `echo` 앞)에 추가한다.

```bash
# --- 7. retired per-cycle paths must not survive in shipped instructions ---
hits="$(grep -rn -e 'docs/blindspot' -e 'YYYY-MM-DD-' -e 'quiz_check.py' -e 'implementation-notes' "$ROOT/skills" "$ROOT/agents" || true)"
[[ -z "$hits" ]] || fail "retired path referenced:"$'\n'"$hits"

# --- 10. every templates/<file> named in a SKILL.md ships in some skill ---
while read -r t; do
  found=0
  for f in "$ROOT"/skills/*/templates/"$t"; do [[ -f "$f" ]] && found=1; done
  [[ $found == 1 ]] || fail "a SKILL.md references templates/$t but no skill ships it"
done < <(grep -ho 'templates/[A-Za-z0-9_.-]*' "$ROOT"/skills/*/SKILL.md | sed 's#templates/##' | sort -u)
```

- [ ] **Step 2: 실패 확인**

Run: `bash test/check.sh`
Expected: `FAIL: retired path referenced:` 뒤에 `skills/blindspot-flow/SKILL.md:12:...docs/blindspot/...` 줄. (검사 7의 대상에 `MANDATE.md`는 Task 9에서 추가한다 — MANDATE는 그 태스크에서 고친다.)

- [ ] **Step 3: blindspot-flow SKILL.md 전체 교체**

```markdown
---
name: blindspot-flow
description: Use when the user invokes /blindspot-flow or asks to run a feature through the full lifecycle end-to-end — thin orchestrator that bootstraps the area's tiers when missing, then sequences requirements-interview, blindspot-pass, explainer, then work-report notes mode through implementation and report mode at the end.
---

# Blindspot Flow

Thin orchestrator. All real logic lives in the four lifecycle skills — this skill only sequences them.

## Workflow

Run the stages below in order, invoking each with the Skill tool by name. Before each stage, look at the touched unit's `docs/<area>/specs/<unit>.md` (found through the 단위 table of `docs/<area>/map.md`): if the section that stage fills already has content for this feature (요구사항 for stage 1, 결정 기록 rows for stage 2, 동작 방식 for stage 3), tell the user (Korean) and offer 실행 or 건너뛰기. Between stages, confirm with the user before proceeding — they may stop or skip any stage.

0. If the area has no `docs/<area>/map.md`, say so (Korean) and offer `blindspot-pass` to bootstrap Tier 1 and 2 first
1. `requirements-interview` → 요구사항 and 결정 기록 rows in the unit spec
2. `blindspot-pass` → findings filed into rules, map, and spec
3. `explainer` → 목적과 배경, 동작 방식, 의도적 범위 제외 in the spec; map updated
4. `work-report` notes mode opens `docs/notes/<slug>.md`; implementation proceeds (implementation itself is outside this skill — only note-keeping is enforced)
5. When implementation is done: `work-report` report mode → tiers promoted, `docs/quiz.html` written; after the user passes the quiz, work-report records the 변경 이력 row and deletes the notes file

Do not inline a stage's logic here; if a stage needs fixing, fix that skill.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries — correct a stale entry's referent instead. -->
- Skipping a stage is the user's call, not yours — always surface the option, never silently skip.
- "Already done" is a judgment on section content for this feature, not on the spec file existing — a 확정 spec from last quarter still needs this feature's interview.
```

- [ ] **Step 4: 통과 확인**

Run: `bash test/check.sh`
Expected: `OK: all checks passed`. 추가 확인: `grep -rn 'docs/blindspot' skills agents` 출력 없음.

- [ ] **Step 5: Commit**

```bash
git add skills/blindspot-flow/SKILL.md test/check.sh
git commit -m "feat: blindspot-flow detects reuse from spec sections, add retired-path and template-reference tripwires"
```

---

### Task 9: MANDATE.md — 계층 표와 읽기 순서

**Files:**
- Modify: `MANDATE.md` (전체 교체), `test/check.sh` (검사 1 확장, 검사 7 대상에 MANDATE 복원, 검사 11 신설)

**Interfaces:**
- Consumes: 스펙 §5의 문구 그대로
- Produces: 소비 프로젝트 매 세션에 주입되는 계층 규칙. 60줄 이하.

- [ ] **Step 1: 실패하는 검사 추가**

`test/check.sh`의 `# --- 1.` 블록 끝(`done` 뒤)에 추가한다.

```bash
for p in 'docs/<area>/rules.md' 'docs/<area>/map.md' 'docs/<area>/specs/<unit>.md' 'docs/quiz.html' 'docs/notes/'; do
  grep -qF "$p" <<<"$out" || fail "mandate.sh output missing tier path $p"
done
```

검사 7 블록의 grep 대상 `"$ROOT/skills" "$ROOT/agents"` 뒤에 `"$ROOT/MANDATE.md"`를 추가한다.

검사 10 블록 뒤(마지막 `echo` 앞)에 추가한다.

```bash
# --- 11. MANDATE.md is injected into every consumer session twice (hook + @import): keep it small ---
[[ "$(wc -l < "$ROOT/MANDATE.md")" -le 60 ]] || fail "MANDATE.md over 60 lines"
```

- [ ] **Step 2: 실패 확인**

Run: `bash test/check.sh`
Expected: `FAIL: mandate.sh output missing tier path docs/<area>/rules.md`.

- [ ] **Step 3: MANDATE.md 전체 교체**

```markdown
# Blindspot Mandate

Injected into every session of this project. These rules are not optional.

## Task-type → required skill

| When... | Invoke FIRST, before any other response |
|---|---|
| The user starts discussing a new feature, change request, or vague requirement | `requirements-interview` |
| Work begins in an unfamiliar codebase/domain, or before writing an implementation plan | `blindspot-pass` |
| The user asks for a spec, design doc, explainer, or "문서로 정리해줘" | `explainer` |
| Implementation starts, or a non-obvious decision / plan deviation happens mid-work | `work-report` (notes mode) |
| Work is declared complete, a merge is prepared, or a report is requested | `work-report` (report mode) |
| The user asks to run a feature through the full lifecycle end-to-end | `blindspot-flow` |

## Documentation tiers

Project knowledge lives in a fixed set of living documents, updated in place. Never create a dated or per-feature document.

| Tier | Path | Holds | Cap |
|---|---|---|---|
| 1 Global Rules | `docs/<area>/rules.md` | invariants, conventions, standard commands, glossary of one area | 60 lines |
| 2 System Map | `docs/<area>/map.md` | units with locations, main flows, integration points, cross-unit risks | 150 lines |
| 3 Detail Spec | `docs/<area>/specs/<unit>.md` | one unit: purpose, requirements, behavior, decisions, edge cases, out-of-scope, open questions, change log | 200 lines |

`<area>` is a directory under `docs/` holding `map.md` — canonically `frontend` and `backend`; a project that is neither uses one area (default `core`). Working files: `docs/notes/<slug>.md` (this cycle's decision notes, deleted at acceptance) and `docs/quiz.html` (the current pre-merge quiz, overwritten).

Loading order: before changing code in an area, read its `rules.md`. Lifecycle skills then read `map.md` and only the specs of the units the task touches — never every spec, never another area's tiers, never old documents under `docs/`. Agents receive tier file paths, never directories. If the touched area has no `map.md`, `blindspot-pass` bootstraps Tier 1 and 2; other skills offer it and proceed.

## Hard rules

1. When a trigger matches, invoke the mapped skill IMMEDIATELY — before clarifying questions, exploration, or any other action.
2. Skills MUST delegate exploration and verification to their designated agents (`codebase-scanner`, `domain-researcher`, `doc-verifier`, `change-analyzer`, `check-runner`). Never dump raw exploration output into the main context.
3. All user-facing deliverables (interview questions, documents, quizzes) are written in Korean.
4. Deliverables are the tier files and the two working files above. Creating any other document under `docs/` is a rule violation.
5. Do not merge or declare work done until the user confirms passing `docs/quiz.html` generated by `work-report`.

## Question policy

Applies to every skill that asks the user anything:

1. Ask only when the answer changes what gets built AND evidence cannot decide it; everything else is decided from evidence and recorded (자체 해소 as a 결정 기록 row, or a notes entry) so reports and quizzes surface it.
2. More than 7 questions queued in one pass signals under-analysis, not thoroughness — run more targeted scans to self-resolve, present at most the top 7 by architecture impact, park the rest.
3. Never block mid-implementation on a reversible decision: take the conservative option, log it at decision time, batch it for the next checkpoint. Irreversible or destructive choices (data loss, external side effects, published contracts) are asked immediately.
4. Calibrate each cycle: if the quiz/review reveals a decision the user never saw, ask more next cycle; if answers come back mechanical or deferred ("알아서 해줘"), self-resolve more and ask less.
```

- [ ] **Step 4: 통과 확인**

Run: `bash test/check.sh; wc -l MANDATE.md`
Expected: `OK: all checks passed`, 줄 수 60 이하(약 46).

- [ ] **Step 5: Commit**

```bash
git add MANDATE.md test/check.sh
git commit -m "feat: MANDATE declares the three documentation tiers, their caps, and the loading order"
```

---
### Task 10: README.md와 CLAUDE.md 동기화

**Files:**
- Modify: `README.md` (전체 교체), `CLAUDE.md` (전체 교체)

**Interfaces:**
- Consumes: Task 1–9의 모든 경로·이름
- Produces: 소비자 가이드와 이 저장소 개발 지침. 검사 대상은 아니지만 스펙 §11의 항목 전부를 담는다.

- [ ] **Step 1: 옛 경로 확인**

Run: `grep -n 'docs/blindspot' README.md CLAUDE.md | wc -l`
Expected: `10` 이상.

- [ ] **Step 2: README.md 전체 교체**

```markdown
# dev-env-blindspot

모든 프로젝트가 공통으로 쓰는 Claude Code Agent/Skill 모음 — 사용자 요구사항 이해, Unknown Unknowns 구체화, 문서 작성, 작업사항 보고.

Thariq(Anthropic)의 ["A Field Guide to Fable: Finding Your Unknowns"](https://x.com/trq212/article/2073100352921215386) 라이프사이클과 ["How We Use Skills"](https://x.com/trq212/status/2033949937936085378)의 skill 설계 원칙을 따른다.

**핵심 아이디어**: 프롬프트는 실제 요구사항의 불완전한 지도일 뿐이다("the map is not the territory"). 이 도구는 코딩을 시작하기 *전에* 당신이 모르는 것(Unknown Unknowns)을 질문으로 바꿔서 해소하고, 작업이 끝나면 리뷰어가 놓치면 안 되는 것을 퀴즈로 확인시킨다. 그 과정에서 알게 된 것은 기능마다 새 문서를 만들지 않고, 프로젝트의 고정된 3계층 문서에 쌓는다.

## 1. 설치 (처음 한 번)

소비하려는 프로젝트의 루트에서 두 명령을 실행한다:

```bash
git submodule add https://github.com/dkdlqoddi/dev-env-blindspot.git .claude/shared
bash .claude/shared/install.sh
```

`install.sh`가 하는 일 (멱등 — 몇 번을 재실행해도 안전):

1. `.claude/skills/`, `.claude/agents/`에 개별 상대 심링크 생성 (프로젝트 자체 skill/agent와 공존)
2. `.claude/settings.json`에 SessionStart hook 병합 — 매 세션 `MANDATE.md`(작업유형→필수 skill 매핑 + 문서 계층 규칙) 주입
3. 프로젝트 `CLAUDE.md`에 `@.claude/shared/MANDATE.md` import 라인 추가 (hook 실패 시 안전망)

설치가 잘 됐는지 확인:

```bash
ls .claude/skills/            # blindspot-flow 등 5개 심링크가 보여야 함
bash .claude/shared/hooks/mandate.sh | head -3   # "# Blindspot Mandate"가 출력되어야 함
```

마지막으로 생성/변경된 파일들(`.gitmodules`, `.claude/`, `CLAUDE.md`)을 커밋하면 팀원들도 같은 환경을 받는다.

## 2. 사용법

설치 후 **새로 시작하는 Claude Code 세션부터** 자동 적용된다. 별도 명령 없이, 매 세션 시작 시 hook이 "이런 작업에는 이 skill을 쓰라"는 규칙과 문서 계층 규칙을 Claude에게 주입한다.

### 문서 3계층

이 도구가 만드는 문서는 영역(frontend, backend)마다 세 층으로 고정되어 있고, 사이클마다 새 파일을 만들지 않고 제자리에서 갱신된다.

| 계층 | 경로 | 담는 것 | 언제 읽나 |
|---|---|---|---|
| Tier 1 Global Rules | `docs/<영역>/rules.md` | 불변 규칙, 관례, 표준 명령, 용어 (60줄 이하) | 그 영역 코드를 바꾸기 전에 항상 |
| Tier 2 System Map | `docs/<영역>/map.md` | 단위 목록과 위치, 주요 흐름, 통합 지점, 단위 간 위험 (150줄 이하) | 위치를 찾거나 흐름을 볼 때 |
| Tier 3 Detail Spec | `docs/<영역>/specs/<단위>.md` | 단위 하나의 목적, 요구사항, 동작, 결정 기록, 엣지케이스, 범위 제외, 열린 질문, 변경 이력 (200줄 이하) | 작업이 닿는 단위만 |

영역은 `docs/` 아래에 `map.md`를 가진 폴더다. 프론트엔드와 백엔드가 각각 세 층을 따로 가지며, 둘 다 아닌 프로젝트(CLI, 라이브러리)는 `core` 하나를 쓴다. 프로젝트 공통 규칙은 프로젝트의 CLAUDE.md가 맡는다.

**첫 실행(부트스트랩)**: 영역에 `map.md`가 없으면 스킬이 `blindspot-pass`로 부트스트랩을 제안한다. 코드를 스캔해 rules.md와 map.md를 만들고 영역 판정 결과를 알려준다(애매할 때만 한 번 묻는다). 상세 명세는 미리 만들지 않고, 작업이 그 단위에 닿을 때 생긴다. 큰 리팩터링 뒤에는 "맵 갱신해줘"라고 하면 기존 문서를 받아 달라진 부분만 고친다.

### 방법 A — 그냥 평소처럼 말하기 (자동 트리거)

작업 유형을 인식하면 Claude가 해당 skill을 스스로 호출한다:

| 이렇게 말하면 | 발동하는 skill | 무슨 일이 일어나나 |
|---|---|---|
| "로그인 기능 추가하고 싶어" | `requirements-interview` | 영역 규칙·맵·과거 결정을 읽은 뒤, 아키텍처에 영향 큰 질문부터 **한 번에 하나씩** 물어보고 확정 요구사항과 결정을 단위 상세 명세에 적는다 |
| "이 코드베이스 처음인데 뭘 조심해야 하지?" / "내가 모르는 게 뭐지?" | `blindspot-pass` | 4개 관점(관례/유사기능/통합지점/엣지케이스)으로 병렬 스캔하고 — 코드 밖 도메인 지식이 필요하면 웹 리서치(domain-researcher)로 보강해서 — 놓치기 쉬운 것들을 "결정 가능한 질문"으로 바꿔 확인받고, 발견을 규칙·맵·명세에 반영한다 |
| "지금까지 결정한 거 문서로 정리해줘" | `explainer` | 단위 상세 명세의 목적·동작·기각한 대안·범위 제외를 완성하고 맵을 갱신한다 |
| (구현을 시작하면 자동) | `work-report` 노트 모드 | 비자명한 결정을 내릴 때마다 `docs/notes/<slug>.md`에 즉시 기록한다 |
| "작업 끝났어, 보고서 만들어줘" / 머지 직전 | `work-report` 보고 모드 | diff를 분석해 노트를 명세·맵에 반영하고 **Pre-Merge Quiz**(`docs/quiz.html`)를 생성한다. 사람용 요약과 리뷰 포인트는 채팅과 PR 본문에 남긴다 |

### 방법 B — 전체 라이프사이클 한 번에 (`blindspot-flow`)

새 기능을 처음부터 끝까지 이 체계로 진행하고 싶으면:

```
카테고리별 월 예산 한도 기능을 추가하고 싶어. blindspot-flow로 진행해줘.
```

그러면 아래 순서로 진행되며, **각 단계 사이마다 계속할지 물어본다** (이미 채워진 단계는 건너뛰기를 제안):

```
⓪ (맵이 없으면) blindspot-pass  코드 스캔 → 영역 rules.md·map.md 생성
① requirements-interview  규칙·맵·과거 결정 확인 → 질문에 하나씩 답하면 → 명세에 요구사항·결정 기록
② blindspot-pass          병렬 스캔 → 놓친 결정사항 확인 → 규칙·맵·명세에 반영
③ explainer               명세의 목적·동작·범위 제외 완성, 맵 갱신
④ (구현 진행)             결정할 때마다 작업 노트 자동 기록
⑤ work-report 보고 모드   노트를 명세에 반영 + Pre-Merge Quiz 생성 → 통과하면 변경 이력 기록, 노트 삭제
```

사용자가 할 일은 **질문에 답하는 것**뿐이다. 질문은 객관식 위주로, 한 번에 하나씩, 코드를 몰라도 답할 수 있는 문장으로 온다.

### 산출물은 어디에 생기나

전부 한국어로, 프로젝트의 `docs/` 아래에 생긴다. 파일 수는 사이클이 늘어도 늘지 않는다:

```
docs/
├── frontend/
│   ├── rules.md            # Tier 1 전역 규칙
│   ├── map.md              # Tier 2 시스템 맵
│   └── specs/
│       └── budget-form.md  # Tier 3 상세 명세 (작업이 닿은 단위만)
├── backend/                # 동일한 3계층
├── notes/
│   └── budget-limit.md     # 작업 중 결정 노트 — 인수 시 삭제
└── quiz.html               # 최신 Pre-Merge Quiz — 사이클마다 덮어씀
```

### Pre-Merge Quiz 사용법

작업 완료 시 생성되는 퀴즈는 "리뷰어가 이 변경에서 반드시 이해해야 할 것"(동작 변화·위험 지점·계획 이탈)을 묻는 객관식 4~6문항이다. 코드를 본 적 없는 사람도 읽을 수 있는 짧은 문장으로 출제되고, 답에 필요한 정보는 퀴즈 페이지의 '변경 요약' 안에 모두 담긴다 — 보고서를 외울 필요가 없다. 퀴즈는 `docs/quiz.html` 한 파일을 덮어쓰며, 통과 기록은 해당 단위 명세의 '변경 이력' 표에 한 줄로 남는다.

1. 브라우저로 연다 — WSL이면: `explorer.exe docs/quiz.html`
2. 문항에 답하고 **정답 확인** 버튼을 누른다 — 문항마다 해설이 나타나고 정답 보기가 강조된다
3. **전부 맞히기 전에는 머지하지 않는다** — 틀린 문항은 해설을 다시 읽고 재시도

## 3. 업데이트

이 저장소가 갱신되면, 소비 프로젝트에서:

```bash
git submodule update --remote .claude/shared
bash .claude/shared/install.sh
```

이미 submodule이 등록된 소비 프로젝트를 새로 clone한 경우에는 먼저 초기화가 필요하다:

```bash
git submodule update --init --recursive
bash .claude/shared/install.sh
```

**3계층 이전 버전에서 올라오는 경우**: 옛 `docs/blindspot/` 문서는 그대로 두면 된다. 어떤 스킬도 자동으로 읽지 않는다. 첫 스킬 실행 때 부트스트랩이 제안된다. 옛 문서의 결정을 새 명세로 옮기고 싶으면 그 파일을 지목해 "이 문서의 결정을 명세로 옮겨줘"라고 요청한다.

## 4. 제공 Skill (라이프사이클 순)

| Skill | 용도 | 갱신하는 문서 |
|---|---|---|
| `requirements-interview` | 구조화된 인터뷰로 요구사항 확정 (한 번에 한 질문, 아키텍처 영향 순) | `specs/<단위>.md` 요구사항·결정 기록·열린 질문 (영역 전체 규칙이면 `rules.md`) |
| `blindspot-pass` | codebase-scanner 병렬 스캔으로 Unknown Unknowns를 결정 가능한 질문으로 구체화. 맵이 없으면 부트스트랩 | `rules.md`, `map.md`, `specs/<단위>.md` |
| `explainer` | 결정사항·대안·범위 제외를 담은 단위 상세 명세 완성 | `specs/<단위>.md` 목적·동작·범위 제외, `map.md` 단위·흐름 |
| `work-report` | (노트) 구현 중 결정 즉시 기록 / (보고) diff 분석 + 명세·맵 반영 + Pre-Merge Quiz | `docs/notes/<slug>.md`, `docs/quiz.html`, 명세 변경 이력 |
| `blindspot-flow` | 위 전체를 순서대로 실행하는 오케스트레이터 | (하위 skill 산출물) |

## 5. 제공 Agent (모두 읽기 전용)

skill들이 탐색·검증을 위임하는 하위 에이전트로, 직접 부를 일은 거의 없다:

| Agent | 역할 |
|---|---|
| `codebase-scanner` | 렌즈(structure/conventions/similar-features/integration-points/edge-cases)별 코드 탐색. 기존 규칙·맵을 받으면 새 것만 `파일:라인` 근거와 반영 계층을 달아 반환 |
| `domain-researcher` | 코드 밖 도메인 지식 웹 리서치 — 핵심 개념·품질 기준·함정을 출처 URL 근거와 반영 계층과 함께 반환 |
| `doc-verifier` | 계층 문서의 placeholder·모순·모호성·범위·계층 위치 검사 |
| `change-analyzer` | base 대비 diff 분석: 변경 요약, 위험 지점(의심 결함 포함), 명세 대비 이탈, 문서 갱신 필요, 테스트 유무, 퀴즈 후보 |
| `check-runner` | 프로젝트 표준 검사(테스트·린트·빌드) 실행 — 실패만 증류해 반환, 전체 로그는 반환 안 함 |

## 6. 규칙

- 산출물은 전부 한국어. `docs/<영역>/`의 3계층 문서와 `docs/notes/`, `docs/quiz.html`에만 저장하고, 사이클마다 새 문서를 만들지 않는다
- 새 사실은 그것을 온전히 담는 가장 낮은 계층에 한 번만 적는다. 줄 상한(60/150/200)을 넘으면 아래 계층으로 내린다
- Pre-Merge Quiz를 전부 맞히기 전에는 머지 금지
- 질문은 답이 설계를 바꾸는 것만 온다 — 근거로 정할 수 있는 것은 스스로 정하고 결정 기록으로 남긴다. 한 pass에 질문이 7개를 넘으면 질문 대신 추가 스캔으로 먼저 줄인다
- 구현 중에는 되돌릴 수 있는 결정으로 작업을 멈추지 않는다 — 보수적 기본값으로 진행, 작업 노트에 기록, 체크포인트에서 일괄 확인 (되돌리기 어려운 결정만 즉시 질문)

## 7. 문제 해결

| 증상 | 원인/해결 |
|---|---|
| `install.sh`가 "not valid JSON" 에러로 실패 | 기존 `.claude/settings.json`이 깨져 있음 — 파일을 고치거나 지운 뒤 재실행 |
| `install.sh`가 python3 없다고 실패 | python3 설치 (`sudo apt install python3`), 또는 에러 메시지에 출력된 hook JSON을 settings.json에 수동 추가 |
| clone 직후 `.claude/skills/` 심링크가 깨져 있음 | submodule 미초기화 — `git submodule update --init --recursive` 후 `install.sh` 재실행 |
| skill이 자동으로 발동하지 않음 | 설치 후 시작한 **새 세션**인지 확인. 그래도 안 되면 skill 이름을 직접 언급 ("blindspot-pass 실행해줘") |
| 병렬 브랜치 둘이 `docs/quiz.html`이나 `docs/notes/`에서 충돌 | 둘 다 일회용 — 내 브랜치 것을 유지하고 필요하면 다시 생성 |
| `map.md`나 명세의 표에서 충돌 | 양쪽 행을 모두 취한다 — 행은 표 끝에 붙으므로 충돌이 줄 단위다 |
| 맵이 실제 코드와 다름 | "맵 갱신해줘" — blindspot-pass가 기존 문서를 받아 달라진 부분만 고친다. 링크 무결성만 따로 보려면 `python3 .claude/skills/work-report/scripts/docs_check.py docs/<영역>/map.md` |
| 네이티브 Windows에서 심링크 오류 | 지원 범위 밖 — Linux / WSL / macOS에서 사용 |

## 8. 이 저장소 개발

```bash
bash test/check.sh   # mandate hook·계층 경로 + frontmatter lint + skill↔agent 참조 + readability 4사본 + installer 멱등성 + docs_check 템플릿·음성 fixture + 폐지 경로·헤딩 계약·템플릿 참조 + MANDATE 상한
```

skill/agent를 추가·제거하면 `test/check.sh`의 파일 수(`-eq 10`)·skill 목록과 `MANDATE.md` 매핑표를 함께 갱신해야 한다 (`CLAUDE.md`의 Consumer contract 체크리스트 참고).

설계 문서: `docs/superpowers/specs/`, 구현 계획: `docs/superpowers/plans/`. 이 저장소 자체의 3계층 문서: `docs/core/`. 3계층 이전 이력(수락된 보고서·퀴즈): `docs/blindspot/`
```

- [ ] **Step 3: CLAUDE.md 전체 교체**

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Shared Claude Code skills/agents that other projects consume as a git submodule mounted at `.claude/shared/`, wired up by `install.sh` (individual relative symlinks into `.claude/skills` and `.claude/agents`, a SessionStart hook running `hooks/mandate.sh`, and a `@.claude/shared/MANDATE.md` import in the consumer's CLAUDE.md). It implements Thariq's "Finding Your Unknowns" lifecycle: `requirements-interview` → `blindspot-pass` → `explainer` → `work-report`, orchestrated by `blindspot-flow`. Deliverables are a fixed set of living documents per area — three tiers, `rules.md` / `map.md` / `specs/<unit>.md` — updated in place, never dated per-cycle files.

## Test

```bash
bash test/check.sh
```

Covers: mandate hook output names all 5 skills and the tier paths; YAML frontmatter lint (`name`, `description`) across exactly 10 files (5 skills + 5 agents); skill↔agent `subagent_type` reference integrity in both directions (every referenced agent exists, every agent is referenced); readability-standard marker (`25 어절`) present in exactly 4 SKILL.md files; `install.sh` idempotency against a fake consumer project in a temp dir (run twice, assert symlinks/settings/CLAUDE.md unchanged); `docs_check.py` running clean on the shipped templates and failing loudly on a broken fixture (over-cap file, dangling map link, unlisted spec, over-long sentence); retired per-cycle strings (`docs/blindspot`, `YYYY-MM-DD-`, `quiz_check.py`, `implementation-notes`) absent from skills/agents/MANDATE; template heading contract; every `templates/<file>` a SKILL.md names ships in some skill; `MANDATE.md` ≤ 60 lines.

Quiz HTML browser verification: Playwright MCP blocks `file://` — serve via `python3 -m http.server` and use localhost.

## Conventions

- Model-facing instruction files (`SKILL.md`, `agents/*.md`, `MANDATE.md`): English. User-facing deliverables the skills generate: Korean. Do not mix.
- Templates (`skills/*/templates/*`): deliverable text and placeholders Korean; instruction comments addressed to the generating model (`<!-- -->`, `//`) English. Cross-referenced identifiers (lens names, tier section headings, quadrant terms) keep their established form. Skills locate sections by exact heading text, so template headings are a contract (checked by `test/check.sh`).
- Template ownership: `rules.md` / `map.md` belong to blindspot-pass, `spec.md` to explainer, `notes.md` / `quiz.html` to work-report. A skill that needs another skill's template names it by skill ("the `explainer` skill's `templates/spec.md`", installed at `.claude/skills/explainer/templates/spec.md`); templates are never duplicated.
- Skill frontmatter `description` is the trigger condition — always "Use when ...".
- Every SKILL.md has a `## Gotchas` section. Append recurring failure points there; never delete entries. When a structural change makes an entry factually wrong, rewrite it to name the new referent — correcting a stale referent is not deletion.
- Agents are read-only by design — they never edit files. Keep `tools` minimal (`Bash` only where git inspection or running the project's standard checks is required, with read-only instructions in the body). Pin cost-appropriate `model` in frontmatter: `haiku` for mechanical checkers (doc-verifier, check-runner), `sonnet` for exploration/research (codebase-scanner, domain-researcher); change-analyzer inherits the session model because it feeds the merge gate.
- Deliverable path contract baked into skills and MANDATE: `docs/<area>/rules.md` (Tier 1, ≤60 lines), `docs/<area>/map.md` (Tier 2, ≤150), `docs/<area>/specs/<unit>.md` (Tier 3, ≤200), `docs/notes/<slug>.md` (deleted at acceptance), `docs/quiz.html` (overwritten each cycle). An area is a directory under `docs/` holding `map.md`; canonical areas are `frontend` and `backend`, a single-area project uses `core`.
- Readers are separated per section, not per document. Non-developer register (plain Korean first with the term in parentheses; no arrows/code syntax; one fact per sentence, ≤25 어절; quiz options ≤40 chars; quiz answerable from its own 변경 요약): spec 목적과 배경 / 요구사항 / 동작 방식 / 의도적 범위 제외, the 결정 and 질문 cells, map 영역 개요 and 하는 일, rules 규칙 cells, interview and blindspot questions, the whole quiz. Technical register: 근거, 위치, 처리, 기각한 대안, 변경 이력, 리뷰 포인트. The standard is intentionally duplicated across 4 skills for self-containment (requirements-interview steps 3–4, blindspot-pass steps 3–5, explainer step 2, work-report report step 4) — edit it in all of them together. The countable subset is enforced by `skills/work-report/scripts/docs_check.py` (quiz sentences/options, spec non-developer sections, tier line caps, map↔spec link integrity).
- Section ownership in a spec: explainer rewrites 목적과 배경 / 동작 방식 / 의도적 범위 제외; requirements-interview appends 요구사항; 결정 기록 / 엣지케이스와 제약 / 열린 질문 are append-only for everyone (rows one line, date first, so `grep -h '^| 20' docs/<area>/specs/*.md` finds past decisions across the area); work-report writes 변경 이력 after the quiz passes. Empty sections are not placeholders.
- Question policy (evidence-first asking, 7-question cap that triggers more scanning instead of more asking, no mid-work blocking on reversible decisions, per-cycle calibration) lives once in `MANDATE.md`; `blindspot-pass` step 4 and `work-report` notes/report modes implement the mechanics. Bootstrap (blindspot-pass step 0) decides areas from evidence and asks only when the evidence conflicts.

## Consumer contract (breaking-change checklist)

Renaming or moving any of these breaks consumer projects — update `install.sh` + `test/check.sh` + `README.md` together:

- `skills/<name>/` directory names (= installed skill names, referenced in `MANDATE.md`)
- `agents/*.md` filenames (= `subagent_type` values referenced inside SKILL.md files)
- `hooks/mandate.sh`, `MANDATE.md` paths (referenced by consumer `settings.json` and CLAUDE.md import line)
- Tier paths `docs/<area>/{rules.md,map.md,specs/}`, `docs/notes/`, `docs/quiz.html` (referenced by MANDATE, every SKILL.md, README, `docs_check.py`)
- `skills/explainer/templates/spec.md` (created by three skills) and `skills/work-report/scripts/docs_check.py` (called from four SKILL.md files)

## Design docs

Founding spec/plan: `docs/superpowers/specs/2026-07-06-blindspot-agents-skills-design.md`, `docs/superpowers/plans/2026-07-06-blindspot-agents-skills.md`. Three-tier documentation structure: `docs/superpowers/specs/2026-09-07-three-tier-docs-design.md`, `docs/superpowers/plans/2026-09-07-three-tier-docs.md`. Later feature cycles accumulate dated spec/plan pairs in the same folders. This repo's own tier documents live in `docs/core/`; `docs/blindspot/` holds pre-tier history (two accepted reports and quizzes) and is not read by any skill.
```

- [ ] **Step 4: 확인**

Run: `bash test/check.sh; grep -n 'docs/blindspot' README.md CLAUDE.md`
Expected: `OK: all checks passed`. grep은 README §3·§8과 CLAUDE.md Design docs의 이력 언급 3줄만.

- [ ] **Step 5: Commit**

```bash
git add README.md CLAUDE.md
git commit -m "docs: sync README and CLAUDE.md with the three-tier documentation structure"
```

---
### Task 11: 실전 검증 — 이 저장소의 core 3계층 문서와 이번 사이클 퀴즈

**Files:**
- Create: `docs/core/rules.md`, `docs/core/map.md`, `docs/core/specs/lifecycle-skills.md`, `docs/quiz.html`

**Interfaces:**
- Consumes: Task 2의 템플릿 헤딩, Task 1의 `docs_check.py`, Task 7의 work-report 보고 모드 규칙(퀴즈 문항 규칙)
- Produces: 이번 변경의 머지 전 퀴즈. 사용자가 통과를 확인하면 컨트롤러가 `docs/core/specs/lifecycle-skills.md` 변경 이력에 한 줄을 붙인다(Task 12).

이 태스크는 새 스킬을 이 저장소에 직접 적용한 결과다. 영역 판정: 저장소에 프론트엔드·백엔드 매니페스트가 없으므로 `core` 하나(스펙 §8-3). 이번 변경의 주 단위는 `lifecycle-skills`(바뀐 파일 대부분이 `skills/`). 부트스트랩 규칙대로 다른 단위의 명세는 만들지 않는다.

- [ ] **Step 1: 실패 확인 — 아직 없는 파일에 대한 검사**

Run: `python3 skills/work-report/scripts/docs_check.py docs/core/rules.md docs/core/map.md docs/core/specs/lifecycle-skills.md docs/quiz.html`
Expected: `FileNotFoundError` (파일 없음).

- [ ] **Step 2: docs/core/rules.md 작성**

```markdown
# core 전역 규칙 (Tier 1)

- 최종 갱신: 2026-09-07
- 코드 루트: . (skills/, agents/, hooks/, install.sh, test/, MANDATE.md)
- 읽는 법: 이 영역의 코드를 바꾸기 전에 항상 먼저 읽는다. 60줄을 넘기지 않는다.

## 불변 규칙

| # | 규칙 | 깨지면 생기는 일 | 근거 |
|---|---|---|---|
| 1 | 지침 파일(SKILL.md, agents, MANDATE)은 영어로, 산출물과 템플릿 본문은 한국어로 쓴다 | 모델 지침이 흔들리고 사용자가 문서를 못 읽는다 | CLAUDE.md Conventions |
| 2 | 에이전트는 파일을 만들거나 고치지 않는다 | 탐색 결과가 저장소와 메인 컨텍스트를 오염시킨다 | agents/*.md Rules |
| 3 | 스킬 폴더 이름, 에이전트 파일 이름, hooks/mandate.sh, MANDATE.md 경로는 소비자 계약이다 | 소비 프로젝트의 심링크와 hook이 끊긴다 | CLAUDE.md Consumer contract, install.sh:13-20 |
| 4 | 모든 SKILL.md는 Gotchas 섹션을 유지하고 항목을 지우지 않는다 | 한 번 잡은 반복 실패가 되살아난다 | CLAUDE.md Conventions |
| 5 | 가독성 표준(25 어절 표지)은 네 스킬에 사본으로 둔다 | 스킬을 단독으로 읽을 때 규칙이 사라진다 | test/check.sh 검사 4 |
| 6 | 계층 문서는 줄 상한(60/150/200)을 넘기지 않는다 | 매 작업이 읽는 문서가 다시 컨텍스트 문제가 된다 | skills/work-report/scripts/docs_check.py |

## 관례

| 분류 | 관례 | 근거 |
|---|---|---|
| 폴더 구조 | skill = skills/<name>/SKILL.md + templates/, agent = agents/<name>.md | install.sh:13-20 |
| 테스트 | bash test/check.sh 하나가 전부. 검사는 번호 붙은 블록이며 실패 시 fail 함수로 즉시 종료 | test/check.sh |
| 의존성 | bash와 python3 표준 라이브러리만 쓴다 | install.sh:25, skills/work-report/scripts/docs_check.py |
| 이름 짓기 | 스킬 description은 "Use when ..."으로 시작한다 | CLAUDE.md Conventions |

## 표준 명령

| 목적 | 명령 |
|---|---|
| test | bash test/check.sh |
| 퀴즈 확인 | python3 -m http.server 8765 --directory docs 후 localhost:8765/quiz.html (Playwright는 file:// 차단) |

## 용어

| 용어 | 쉬운 말 설명 | 출처 |
|---|---|---|
| 소비 프로젝트 | 이 저장소를 submodule로 붙여 쓰는 다른 프로젝트 | README §1 |
| 머지 전 퀴즈 | 변경을 리뷰어가 이해했는지 확인하는 객관식 관문. 전부 맞혀야 머지 | README §2 |
| 계층 문서 | 영역마다 규칙·지도·상세 명세 세 층으로 고정된 살아 있는 문서 | MANDATE.md Documentation tiers |
```

- [ ] **Step 3: docs/core/map.md 작성**

```markdown
# core 시스템 맵 (Tier 2)

- 최종 갱신: 2026-09-07
- 코드 루트: .
- 읽는 법: 이 영역을 건드리는 작업이 rules.md 다음에 읽는다. 상세는 '단위' 표의 상세 명세로 내려간다. 150줄을 넘기지 않는다.

## 영역 개요

이 저장소는 다른 프로젝트가 가져다 쓰는 Claude Code 스킬과 에이전트 묶음이다. 스킬은 작업 순서를 알려주는 지침서이고, 에이전트는 탐색과 검증을 대신 하는 읽기 전용 일꾼이다. 설치 스크립트가 소비 프로젝트에 이것들을 연결하고, 매 세션 시작 때 규칙(MANDATE)을 주입한다. 검사 스크립트 하나가 저장소 전체의 계약을 지킨다.

## 단위

| 단위 | 하는 일 | 위치 | 상세 명세 |
|---|---|---|---|
| lifecycle-skills | 요구사항 인터뷰부터 보고까지 다섯 스킬의 지침 | skills/*/SKILL.md | specs/lifecycle-skills.md |
| templates | 스킬이 만드는 문서의 틀(계층 3종, 노트, 퀴즈) | skills/*/templates/* | 없음 |
| agents | 스캔·리서치·검증·diff 분석·검사 실행 에이전트 5종 | agents/*.md | 없음 |
| docs-check | 퀴즈와 계층 문서의 기계 검사 | skills/work-report/scripts/docs_check.py | 없음 |
| installer | 소비 프로젝트에 심링크·hook·import를 설치 | install.sh | 없음 |
| mandate | 매 세션 주입되는 규칙과 그것을 출력하는 hook | MANDATE.md, hooks/mandate.sh | 없음 |
| repo-check | 저장소 자체 검사 | test/check.sh | 없음 |

## 주요 흐름

| 흐름 | 시작점 | 거치는 단위 순서 |
|---|---|---|
| 소비 프로젝트 설치 | bash .claude/shared/install.sh | installer → mandate |
| 기능 라이프사이클 | 사용자 요청 (mandate 트리거) | lifecycle-skills → agents → templates → docs-check |
| 저장소 변경 검증 | bash test/check.sh | repo-check → docs-check |

## 통합 지점

| 상대 | 방식 | 계약 위치 | 관련 단위 |
|---|---|---|---|
| 소비 프로젝트 | git submodule + 상대 심링크 + SessionStart hook + CLAUDE.md @import | install.sh, README §1 | installer, mandate |
| Claude Code | skills/agents frontmatter 규격, subagent_type 이름 | skills/*/SKILL.md, agents/*.md | lifecycle-skills, agents |

## 알려진 위험

| 위험 | 영향 단위 | 상태 |
|---|---|---|
| 스킬·에이전트 이름 변경이 소비 프로젝트 심링크를 끊음 | installer, lifecycle-skills, agents | test/check.sh 검사 2·3·10이 감시 |
| MANDATE가 hook과 @import로 두 번 주입되어 크기가 곧 비용 | mandate, installer | 60줄 상한(검사 11). 이중 주입 해소는 후속 과제 |
```

- [ ] **Step 4: docs/core/specs/lifecycle-skills.md 작성**

```markdown
# lifecycle-skills 상세 명세 (Tier 3)

- 영역: core
- 위치: skills/*/SKILL.md
- 최종 갱신: 2026-09-07
- 상태: 확정
- 읽는 법: '목적과 배경', '요구사항', '동작 방식', '의도적 범위 제외'는 코드를 모르는 분도 읽을 수 있게 씁니다. 그 외는 개발자와 AI를 위한 상세입니다.

## 목적과 배경

이 단위는 기능 하나를 진행하는 다섯 가지 작업 지침(스킬)의 묶음입니다. 요구사항 인터뷰, 사각지대 점검, 설계 설명, 작업 중 기록, 완료 보고 순서로 이어집니다. 예전에는 단계마다 날짜 붙은 문서를 새로 만들어 문서가 계속 쌓였습니다. 이제는 영역별 세 층 문서를 제자리에서 고칩니다.

## 요구사항

1. 작업 문서는 영역마다 규칙, 지도, 상세 명세의 세 층으로 고정되고 파일 수가 늘지 않는다. (사용자 요청 2026-09-07)
2. 프론트엔드와 백엔드가 각각 세 층을 따로 가진다. (사용자 요청 2026-09-07)
3. 세 층은 소비 프로젝트의 docs 폴더 바로 아래 영역 폴더에 둔다. (사용자 답변, 인터뷰 1문)
4. 사이클마다 만들던 보고서 파일은 없앤다. 사람용 요약은 퀴즈와 채팅에, 인수 기록은 명세의 변경 이력에 남긴다. (사용자 답변, 인터뷰 2문)
5. 머지 전 퀴즈는 한 파일을 덮어쓴다. (사용자 승인 트리)
6. 스킬과 에이전트의 이름과 수는 바꾸지 않는다. (소비자 계약)

## 동작 방식

새 기능 이야기가 시작되면 인터뷰 스킬이 그 영역의 규칙과 지도를 먼저 읽습니다. 과거 결정은 영역 안 모든 명세의 결정 기록 줄을 한 번에 훑어 찾습니다. 그래서 이미 답한 것은 다시 묻지 않습니다. 답은 해당 부품(단위)의 상세 명세에 요구사항과 결정으로 적힙니다. 사각지대 점검은 코드를 여러 관점으로 훑고, 발견을 규칙·지도·명세 중 맞는 곳에 넣습니다. 지도가 아직 없는 프로젝트라면 이 단계가 규칙과 지도를 처음 만듭니다. 설계 설명 스킬은 명세의 목적, 동작, 뺀 것을 완성합니다. 구현 중 결정은 작업 노트 파일에만 적습니다. 작업이 끝나면 보고 스킬이 노트를 명세에 옮기고 퀴즈 한 장을 만듭니다. 사용자가 퀴즈를 통과하면 명세에 변경 이력 한 줄이 남고 노트는 지워집니다.

## 결정 기록

| 날짜 | 결정 | 근거 | 기각한 대안 | 결정 주체 |
|---|---|---|---|---|
| 2026-09-07 | 세 층을 docs/<영역>/ 아래에 두고 규칙도 영역마다 둔다 | 반대편 영역 규칙을 읽지 않아도 됨. 사용자 선택 | Tier 1을 프로젝트 공통 하나로 / docs/blindspot/ 아래 유지 | 사용자 |
| 2026-09-07 | 보고서 파일을 없앤다 | 스냅샷은 머지 후 읽히지 않음. 사용자 선택 | CHANGELOG 하나에 누적 / 사이클별 보고서 유지 | 사용자 |
| 2026-09-07 | 구현 노트는 docs/notes/<slug>.md에 두고 인수 시 지운다 | 명세에 직접 쓰면 명세가 없을 때 멈추고 explainer 재실행이 덮어씀 (설계 반박 검토) | 명세 안 '작업 중' 섹션 | 자체 |
| 2026-09-07 | 과거 결정은 결정 기록 행을 grep해 찾는다 | 닿는 명세만 읽으면 인접 단위 결정을 다시 묻게 됨 (반박 검토 3건) | 영역 결정 색인 파일 / 명세 전부 읽기 | 자체 |
| 2026-09-07 | 부트스트랩은 blindspot-pass 0단계이며 MANDATE 트리거가 아니다 | 트리거로 두면 규칙 1과 충돌하고 첫 접촉에 스캐너 8개가 돎 | 여섯 번째 스킬 / MANDATE 트리거 행 | 자체 |
| 2026-09-07 | 줄 상한 rules 60 / map 150 / spec 200, docs_check.py가 실패시킴 | 컨텍스트 천장을 고정하는 유일한 구조적 장치 | 상한 없음 / 경고만 | 자체 |
| 2026-09-07 | 영역이 둘 다 아닌 프로젝트는 core 하나를 쓴다 | 단일 레이아웃 유지, 영역이 늘어도 이동 없음 | 영역 폴더 생략 | 자체 |

## 엣지케이스와 제약

| 상황 | 처리 | 근거 |
|---|---|---|
| 병렬 브랜치 둘이 quiz.html이나 notes를 동시에 수정 | 둘 다 일회용. 내 브랜치 것을 유지 | README §7 |
| 지도가 없는 영역에서 인터뷰나 explainer가 먼저 호출됨 | 부트스트랩을 제안만 하고 명세만 쓰며 진행 | 스펙 §8-6 |
| 명세 파일이 없는 단위에서 구현 중 결정 발생 | 노트 파일에만 적으므로 명세 없이 진행 | work-report 노트 모드 1단계 |
| 스캔 발견이 어느 계층에도 맞지 않음 | 버린다. 원본 요약을 남기지 않음 | blindspot-pass 5단계 |
| 사용자 확인 필요 항목이 있는 채로 보고 모드 진입 | 계층 승격 전에 먼저 묻는다 | work-report 보고 모드 2단계 |
| 명세가 200줄에 근접 | 변경 이력의 오래된 행부터 정리. git이 보존 | spec.md 템플릿 주석 |

## 의도적 범위 제외

- 여섯 번째 스킬(맵 전용)은 만들지 않는다. blindspot-pass 0단계로 충분하다.
- install.sh는 손대지 않는다. 끊어진 심링크 정리와 MANDATE 이중 주입 해소는 후속 과제다.
- 브랜치별 퀴즈 파일은 만들지 않는다. 팀 병렬 작업이 잦아지면 재검토한다.
- 옛 문서 자동 수확은 하지 않는다. 사용자가 파일을 지목할 때만 옮긴다.

## 열린 질문

| 질문 | 해소 계획 | 재방문 시점 |
|---|---|---|
| 줄 상한 60/150/200이 실제 소비 프로젝트에 맞는가 | 첫 소비 프로젝트에서 두 사이클 뒤 실측 | 2026-10 |

## 변경 이력

| 날짜 | 변경 요약 | 기준 커밋 | 검증 | 퀴즈 |
|---|---|---|---|---|
```

- [ ] **Step 5: docs/quiz.html 작성**

```html
<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>머지 전 퀴즈: 3계층 문서 구조</title>
<style>
  body { font-family: sans-serif; max-width: 720px; margin: 2rem auto; padding: 0 1rem; line-height: 1.6; }
  .q { border: 1px solid #ccc; border-radius: 8px; padding: 1rem; margin: 1rem 0; }
  .q.correct { border-color: #2e7d32; background: #edf7ed; }
  .q.wrong { border-color: #c62828; background: #fdecea; }
  #result { font-size: 1.2rem; font-weight: bold; margin: 1rem 0; }
  button { padding: .6rem 1.2rem; font-size: 1rem; cursor: pointer; }
  .summary { background: #f5f5f5; border-radius: 8px; padding: 1rem; }
  label { display: block; }
  label.answer { color: #2e7d32; font-weight: bold; }
  .explain { background: #fff8e1; border-radius: 6px; padding: .5rem .8rem; margin-top: .5rem; }
  .meta { color: #666; font-size: .9rem; margin: -.5rem 0 1rem; }
</style>
</head>
<body>
<h1>머지 전 퀴즈: 3계층 문서 구조</h1>
<p class="meta">대상: docs/core/specs/lifecycle-skills.md · 기준: f2d473d</p>
<div class="summary">
<h2>변경 요약</h2>
<p>AI가 만들던 작업 문서를 기능마다 새 파일로 쌓는 대신, 영역별로 고정된 세 층의 문서를 제자리에서 고치도록 바꿨습니다. 첫 층은 그 영역의 규칙이고, 둘째 층은 구성 지도이며, 셋째 층은 부품(단위)마다 하나씩 있는 상세 명세입니다. 프론트엔드와 백엔드는 각각 세 층을 따로 가집니다. 사이클마다 만들던 보고서 파일은 없어지고, 사람용 요약은 이 퀴즈와 채팅에 남습니다. 머지 전 퀴즈는 한 파일을 덮어쓰고, 작업 중 결정 노트는 인수가 끝나면 지워집니다. 문서가 정해진 길이를 넘거나 지도가 없는 명세를 가리키면 검사 도구가 막습니다. 지도가 아직 없는 프로젝트에서는 사각지대 점검 스킬이 먼저 규칙과 지도를 만들어 줍니다.</p>
</div>
<h2>퀴즈 — 전부 맞혀야 머지 가능</h2>
<p>답을 고르는 데 필요한 내용은 위 '변경 요약'에 모두 들어 있습니다.</p>
<div id="quiz"></div>
<button onclick="grade()">정답 확인</button>
<div id="result"></div>
<script>
const QUESTIONS = [
  { q: "새 기능 작업을 마쳤습니다. 작업 문서는 어떻게 되나요?",
    options: ["기능 이름의 새 문서가 생긴다", "기존 세 층 문서가 제자리에서 고쳐진다", "보고서 파일이 하나 추가된다"], answer: 1,
    explain: "문서는 영역별 세 층으로 고정되어 있고 제자리에서 갱신됩니다. 기능마다 새 문서를 만들던 방식과 사이클별 보고서 파일은 없어졌습니다." },
  { q: "작업 중 결정 노트가 있습니다. 인수가 끝나면 이 노트는 어떻게 되나요?",
    options: ["지워진다", "그대로 남는다", "보고서로 바뀐다"], answer: 0,
    explain: "노트의 내용은 상세 명세로 옮겨진 뒤 파일은 지워집니다(docs/notes/<slug>.md). 보고서 파일은 더 이상 만들지 않습니다." },
  { q: "프론트엔드 규칙 문서를 쓰고 있습니다. 백엔드 규칙은 어디에 적나요?",
    options: ["프로젝트 공통 문서 하나에 모은다", "프론트엔드 규칙 문서에 함께 적는다", "백엔드 영역의 규칙 문서에 따로 적는다"], answer: 2,
    explain: "프론트엔드와 백엔드는 각각 세 층을 따로 가집니다. 규칙(Tier 1)도 영역마다 따로 두어 작업과 무관한 규칙을 읽지 않게 합니다." },
  { q: "지도 문서가 존재하지 않는 명세 파일을 가리키고 있습니다. 무슨 일이 생기나요?",
    options: ["경고만 하고 넘어간다", "검사 도구가 작업을 막는다", "빈 명세 파일이 자동으로 생긴다"], answer: 1,
    explain: "검사 도구(docs_check.py)가 지도의 링크와 문서 길이를 확인하고 위반이 있으면 실패시킵니다. 파일을 자동으로 만들지는 않습니다." },
  { q: "새 프로젝트에 지도 문서가 아직 없습니다. 누가 먼저 만드나요?",
    options: ["사각지대 점검 스킬이 규칙과 지도를 만든다", "사용자가 직접 빈 파일을 만들어야 한다", "설계 설명 스킬이 명세부터 만든다"], answer: 0,
    explain: "지도가 없으면 사각지대 점검(blindspot-pass)이 코드를 훑어 규칙과 지도를 먼저 만듭니다. 상세 명세는 작업이 그 부품에 닿을 때 생깁니다." },
];
const quiz = document.getElementById("quiz");
QUESTIONS.forEach((it, i) => {
  const d = document.createElement("div");
  d.className = "q"; d.id = "q" + i;
  d.innerHTML = "<p><b>Q" + (i + 1) + ".</b> " + it.q + "</p>" +
    it.options.map((o, j) =>
      '<label><input type="radio" name="q' + i + '" value="' + j + '"> ' + o + "</label>"
    ).join("") +
    '<div class="explain" hidden><b>해설.</b> ' + it.explain + "</div>";
  quiz.appendChild(d);
});
function grade() {
  let ok = 0;
  QUESTIONS.forEach((it, i) => {
    const sel = document.querySelector('input[name="q' + i + '"]:checked');
    const el = document.getElementById("q" + i);
    const good = sel && Number(sel.value) === it.answer;
    el.className = "q " + (good ? "correct" : "wrong");
    el.querySelectorAll("label")[it.answer].classList.add("answer");
    el.querySelector(".explain").hidden = false;
    if (good) ok++;
  });
  const r = document.getElementById("result");
  r.textContent = ok === QUESTIONS.length
    ? "통과 (" + ok + "/" + QUESTIONS.length + ") — 머지 가능"
    : "미통과 (" + ok + "/" + QUESTIONS.length + ") — 오답 확인 후 재시도. 머지 금지";
}
</script>
</body>
</html>
```

- [ ] **Step 6: 기계 검사와 브라우저 확인**

Run:
```bash
python3 skills/work-report/scripts/docs_check.py docs/core/rules.md docs/core/map.md docs/core/specs/lifecycle-skills.md docs/quiz.html
bash test/check.sh
wc -l docs/core/rules.md docs/core/map.md docs/core/specs/lifecycle-skills.md
```
Expected: `OK`, `OK: all checks passed`, 줄 수가 각각 60·150·200 이하.

브라우저 확인(Playwright MCP가 있을 때): `python3 -m http.server 8765 --directory docs`를 백그라운드로 띄우고 `http://localhost:8765/quiz.html`을 연다. 문항 5개에 정답(2번째, 1번째, 3번째, 2번째, 1번째 보기)을 고르고 '정답 확인'을 누르면 `통과 (5/5) — 머지 가능`이 보이고 해설 5개가 펼쳐진다. 콘솔 오류 없음. 확인 후 서버를 내린다. Playwright가 없으면 이 확인은 컨트롤러가 맡는다.

- [ ] **Step 7: Commit과 push**

```bash
git add docs/core docs/quiz.html
git commit -m "docs: bootstrap this repo's core tiers and generate the pre-merge quiz for the three-tier cycle"
git push origin main
```

---

### Task 12: 인수 — 퀴즈 통과 확인 뒤 변경 이력 기록 (컨트롤러가 사용자 확인 후 실행)

**Files:**
- Modify: `docs/core/specs/lifecycle-skills.md` (변경 이력 행 한 줄)

- [ ] **Step 1: 사용자에게 퀴즈를 안내한다**

한국어로: `docs/quiz.html`을 브라우저로 열어(WSL이면 `explorer.exe docs/quiz.html`) 전부 맞히기 전에는 머지하지 말 것. 채팅에는 사람용 요약 3–5문장과 리뷰 포인트(파일:라인)를 함께 출력한다.

- [ ] **Step 2: 사용자가 통과를 확인하면 변경 이력 행을 붙인다**

`## 변경 이력` 표 끝에 추가:

```markdown
| 2026-09-07 | 사이클별 문서를 영역별 3계층 문서로 바꾸고 퀴즈를 한 파일로 통합 | f2d473d | bash test/check.sh 통과 | 2026-09-07 통과 |
```

- [ ] **Step 3: 검사, 커밋, push**

```bash
python3 skills/work-report/scripts/docs_check.py docs/core/specs/lifecycle-skills.md && bash test/check.sh
git add docs/core/specs/lifecycle-skills.md
git commit -m "docs: record acceptance of the three-tier cycle in the lifecycle-skills spec"
git push origin main
```
