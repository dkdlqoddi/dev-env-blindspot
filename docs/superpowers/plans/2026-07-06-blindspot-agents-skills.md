# Blindspot Agents/Skills Repository Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the cross-project Claude Code agents/skills repository (5 lifecycle skills, 3 read-only agents, session mandate hook, idempotent consumer installer, single check script) per the approved spec at `docs/superpowers/specs/2026-07-06-blindspot-agents-skills-design.md`.

**Architecture:** Pure content repo — markdown skill/agent definitions plus two bash scripts. Consumers mount it as a git submodule at `.claude/shared/` and run `install.sh`, which symlinks skills/agents into `.claude/`, merges a SessionStart hook into `.claude/settings.json`, and appends a CLAUDE.md import. Enforcement = hook injecting `MANDATE.md` every session + CLAUDE.md import as fallback.

**Tech Stack:** Bash (scripts + tests), Markdown with YAML frontmatter (Claude Code SKILL.md / agent format), one self-contained HTML template.

## Global Constraints

- Model-facing instruction files (`SKILL.md`, `agents/*.md`, `MANDATE.md`) are written in **English**; all deliverables the skills generate for users are **Korean**. (spec §2)
- Skill deliverable paths in consumer projects: `docs/blindspot/YYYY-MM-DD-<slug>-{requirements,unknowns,explainer,report}.md`, quiz at `docs/blindspot/quiz/YYYY-MM-DD-<slug>.html`. Exception: `docs/blindspot/<slug>-implementation-notes.md` has no date prefix. (spec §4)
- Skill frontmatter `description` states the **trigger condition** ("Use when ..."). Every SKILL.md has a `## Gotchas` section. (spec §4)
- Agents are read-only: tools limited to `Read, Grep, Glob` (+ `Bash` only where git commands are needed, with read-only instruction). (spec §5)
- `install.sh` must be idempotent — second run changes nothing. Symlinks are **relative** (`../shared/...`). Requires jq or python3 for settings merge; fails with manual instructions otherwise. (spec §7)
- Target platforms: Linux / WSL / macOS. Native Windows out of scope. (spec §7)
- No external dependencies beyond bash + coreutils + (jq|python3).
- Commit after every task. Commit messages end with:
  `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- Push to `origin main` only in the final task.

---

### Task 1: Mandate (MANDATE.md + hooks/mandate.sh) with check script seed

**Files:**
- Create: `test/check.sh`
- Create: `MANDATE.md`
- Create: `hooks/mandate.sh`

**Interfaces:**
- Produces: `MANDATE.md` (injected text; names all 5 skills — later tasks must keep these names: `requirements-interview`, `blindspot-pass`, `explainer`, `work-report`, `blindspot-flow`), `hooks/mandate.sh` (stdout = MANDATE.md content; referenced by install.sh in Task 6 as `.claude/shared/hooks/mandate.sh`), `test/check.sh` (grows in Tasks 2 and 6).

- [ ] **Step 1: Write the failing check (section 1 of test/check.sh)**

Create `test/check.sh`:

```bash
#!/usr/bin/env bash
# Repo self-check: mandate hook, frontmatter lint, installer idempotency.
set -euo pipefail
shopt -s nullglob
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

# --- 1. mandate hook outputs the skill mapping ---
out="$(bash "$ROOT/hooks/mandate.sh")"
for skill in requirements-interview blindspot-pass explainer work-report blindspot-flow; do
  grep -q "$skill" <<<"$out" || fail "mandate.sh output missing $skill"
done

echo "OK: all checks passed"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash test/check.sh`
Expected: exits non-zero — `hooks/mandate.sh: No such file or directory`

- [ ] **Step 3: Write MANDATE.md**

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

## Hard rules

1. When a trigger matches, invoke the mapped skill IMMEDIATELY — before clarifying questions, exploration, or any other action.
2. Skills MUST delegate exploration and verification to their designated agents (`codebase-scanner`, `doc-verifier`, `change-analyzer`). Never dump raw exploration output into the main context.
3. All user-facing deliverables (interview questions, documents, reports, quizzes) are written in Korean.
4. Deliverables live under `docs/blindspot/` in the consumer project.
5. Do not merge or declare work done until the user confirms passing the pre-merge quiz generated by `work-report`.
```

- [ ] **Step 4: Write hooks/mandate.sh**

```bash
#!/usr/bin/env bash
# SessionStart hook: print MANDATE.md to stdout so it is injected into session context.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cat "$DIR/../MANDATE.md"
```

Then: `chmod +x hooks/mandate.sh test/check.sh`

- [ ] **Step 5: Run check to verify it passes**

Run: `bash test/check.sh`
Expected: `OK: all checks passed`

- [ ] **Step 6: Commit**

```bash
git add MANDATE.md hooks/mandate.sh test/check.sh
git commit -m "feat: add session mandate and hook with self-check seed

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: Three read-only agents + frontmatter lint

**Files:**
- Create: `agents/codebase-scanner.md`
- Create: `agents/doc-verifier.md`
- Create: `agents/change-analyzer.md`
- Modify: `test/check.sh` (append section 2 before the final `echo`)

**Interfaces:**
- Produces: agent names `codebase-scanner`, `doc-verifier`, `change-analyzer` — Tasks 3–4 reference them as `subagent_type` values verbatim. Lens names produced by scanner: `conventions`, `similar-features`, `integration-points`, `edge-cases` (blindspot-pass consumes these).

- [ ] **Step 1: Append failing lint to test/check.sh**

Insert before the final `echo "OK: all checks passed"` line:

```bash
# --- 2. frontmatter lint (skills + agents) ---
files=("$ROOT"/skills/*/SKILL.md "$ROOT"/agents/*.md)
[[ ${#files[@]} -ge 3 ]] || fail "expected at least 3 lintable files, got ${#files[@]}"
for f in "${files[@]}"; do
  [[ "$(head -n1 "$f")" == "---" ]] || fail "$f: missing frontmatter open"
  fm="$(awk '/^---$/{c++; next} c==1' "$f")"
  grep -q '^name:' <<<"$fm" || fail "$f: missing name"
  grep -q '^description:' <<<"$fm" || fail "$f: missing description"
done
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash test/check.sh`
Expected: `FAIL: expected at least 3 lintable files, got 0`

- [ ] **Step 3: Write agents/codebase-scanner.md**

```markdown
---
name: codebase-scanner
description: Read-only codebase explorer. Spawned by blindspot skills with ONE assigned lens (conventions, similar-features, integration-points, or edge-cases) plus a task description; returns structured findings with file:line evidence so exploration never pollutes the main context.
tools: Read, Grep, Glob, Bash
---

You are a read-only codebase scanner. You receive ONE lens and a task description. Explore the repository through that lens only and return structured findings.

## Lenses

- `conventions` — naming, layering, error handling, logging, test patterns this codebase already follows
- `similar-features` — prior art: how comparable features were built here, which files they touched, what they reused
- `integration-points` — everything the described change must touch or that touches it: APIs, schemas, configs, build, CI
- `edge-cases` — failure modes, concurrency, permissions, platform quirks, external constraints relevant to the task

## Rules

- READ-ONLY. Never create, edit, or delete files. Bash is for read-only commands only (git log/show/diff, ls, wc, find).
- Every finding must cite evidence as `path:line` (or `path` for whole-file facts). No evidence, no finding.
- Prefer depth over breadth: 3–8 solid findings beat 20 shallow ones.
- If the repo has no code relevant to your lens, say so explicitly — that is itself a finding.

## Output format (your final message, in Korean)

### 스캔 결과: <lens>

- **[F1] <발견 제목>**
  - 근거: `path:line`
  - 내용: <무엇을 발견했는지 1–3문장>
  - 결정 필요: <이 발견이 요구하는 구체적 질문, 없으면 "없음">

(F2, F3, ... 반복)

### 렌즈 총평

<이 렌즈에서 본 위험도와 확신도, 2–3문장>
```

- [ ] **Step 4: Write agents/doc-verifier.md**

```markdown
---
name: doc-verifier
description: Read-only document verifier. Spawned after any blindspot deliverable is written; checks the given file for placeholders, internal contradictions, ambiguous statements, and scope creep, returning PASS or a numbered Korean issue list.
tools: Read, Grep, Glob
---

You are a document verifier. You receive one file path. Read it and check exactly four things:

1. **Placeholders** — TBD, TODO, 미정, empty sections, template text left unfilled (e.g. `[주제]`, `YYYY-MM-DD` literals)
2. **Contradictions** — statements in one section that conflict with another
3. **Ambiguity** — any requirement or decision readable in two different ways
4. **Scope** — content beyond the document's stated purpose, or a purpose too broad for one document

## Rules

- READ-ONLY. Report; never fix.
- Judge only the document (and files it explicitly links, if needed for contradiction checks). Do not review code quality.
- Be strict about placeholders, lenient about style.

## Output format (your final message, in Korean)

If clean:

PASS — 지적사항 없음

Otherwise:

1. [심각도: 높음|중간|낮음] [유형: placeholder|모순|모호성|범위] <섹션명>: <문제> → 제안: <수정 방향>
2. ...
```

- [ ] **Step 5: Write agents/change-analyzer.md**

```markdown
---
name: change-analyzer
description: Read-only git diff analyst. Spawned by work-report (report mode) with a base ref; analyzes changes between the base and HEAD and returns a structured Korean summary with per-file changes, risk spots, test coverage presence, and quiz question candidates.
tools: Read, Grep, Glob, Bash
---

You are a git change analyst. You receive a base ref (if none given, use `git merge-base main HEAD`; if that fails, use the first commit).

## Procedure

1. `git diff --stat <base>...HEAD` for the shape of the change
2. `git diff <base>...HEAD` and `git log --oneline <base>..HEAD` for content
3. Read changed files where the diff alone is unclear
4. Check whether tests covering the changed behavior exist (look for test files touching the changed modules)

## Rules

- READ-ONLY. Bash is for read-only git/inspection commands only.
- Cite `path:line` for every risk spot.
- Quiz candidates must target behavior and risk, never trivia (no "how many files changed").

## Output format (your final message, in Korean)

### 변경 요약

<2–4문장>

### 파일별 핵심 변경

| 파일 | 핵심 변경 |
|---|---|

### 위험 지점

- `path:line` — <왜 위험한지>

### 테스트

<변경 동작을 덮는 테스트 유무와 위치>

### 퀴즈 후보 (4–6개)

1. <리뷰어가 반드시 이해해야 할 포인트를 묻는 질문> — 정답: <요지>
```

- [ ] **Step 6: Run check to verify it passes**

Run: `bash test/check.sh`
Expected: `OK: all checks passed`

- [ ] **Step 7: Commit**

```bash
git add agents/ test/check.sh
git commit -m "feat: add read-only agents (codebase-scanner, doc-verifier, change-analyzer)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: requirements-interview + blindspot-pass skills

**Files:**
- Create: `skills/requirements-interview/SKILL.md`
- Create: `skills/requirements-interview/templates/requirements.md`
- Create: `skills/blindspot-pass/SKILL.md`
- Create: `skills/blindspot-pass/templates/unknowns.md`

**Interfaces:**
- Consumes: agent names from Task 2 (`codebase-scanner`, `doc-verifier`) and scanner lens names verbatim.
- Produces: deliverable filename patterns `YYYY-MM-DD-<slug>-requirements.md` / `YYYY-MM-DD-<slug>-unknowns.md` (read back by `explainer` and `blindspot-flow`); skill names `requirements-interview`, `blindspot-pass` referenced by MANDATE.md (Task 1) and `blindspot-flow` (Task 5).

- [ ] **Step 1: Write skills/requirements-interview/SKILL.md**

```markdown
---
name: requirements-interview
description: Use when the user starts discussing a new feature, change request, or any task with unclear requirements — runs a structured Korean interview (one question at a time, architecture-changing questions first) grounded in codebase reality, then writes a requirements document with a four-quadrant unknowns map.
---

# Requirements Interview

The user's first prompt is a lossy map of what they actually need. Recover the territory by interviewing before building.

## Workflow

1. **Classify first.** Sort what you know into the four quadrants:
   - Known Knowns — explicitly stated in the request
   - Known Unknowns — questions you already know need answers
   - Unknown Knowns — preferences the user likely holds but hasn't said (naming, style, existing patterns)
   - Unknown Unknowns — territory nobody has looked at; note candidates, leave the digging to `blindspot-pass`

2. **Ground before asking.** Spawn ONE `codebase-scanner` agent (subagent_type: `codebase-scanner`) with lens `conventions` and the task description BEFORE writing questions. Questions that ignore the actual code waste the user's time. Skip only if the project has no code yet.

3. **Interview.** In Korean, ONE question per message, via AskUserQuestion with 2–4 concrete options where possible.
   - Order by architecture impact: answers that change the design come first.
   - Stop when remaining answers would no longer change what you'd build (typically 3–6 questions).
   - Record every question, answer, and its architecture impact.

4. **Write the document.** Follow `templates/requirements.md` in this skill's folder. Fill every section in Korean. Save to `docs/blindspot/YYYY-MM-DD-<slug>-requirements.md` (slug = kebab-case topic, date = today).

5. **Verify.** Spawn `doc-verifier` (subagent_type: `doc-verifier`) on the saved file. Fix every reported issue, re-save. Do not skip on PASS-looking drafts — verification is not optional.

6. **Hand off.** Tell the user (Korean): 다음 단계는 `blindspot-pass`로 Unknown Unknowns를 구체화하는 것.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- Never ask the user something answerable by reading the code — that is what the scanner run is for.
- One decision per question. Batched questions get half-answers.
```

- [ ] **Step 2: Write skills/requirements-interview/templates/requirements.md**

```markdown
# [주제] 요구사항

- 날짜: YYYY-MM-DD
- 상태: 초안 | 확정
- 관련 문서: (unknowns / explainer 링크, 없으면 "없음")

## 요청 배경

(사용자가 이 요청을 하게 된 맥락 1–3문장)

## Unknowns 4분면

| 분면 | 항목 |
|---|---|
| Known Knowns (명시된 요구사항) | |
| Known Unknowns (답이 필요한 질문) | |
| Unknown Knowns (인터뷰로 드러난 암묵적 선호) | |
| Unknown Unknowns (미지 영역 — blindspot-pass 대상) | |

## 확정 요구사항

1. (인터뷰로 확정된 항목 — 근거가 된 답변 인용)

## 인터뷰 기록

| 질문 | 답변 | 아키텍처 영향 |
|---|---|---|

## 미해결 질문

- (남은 Known Unknowns — blindspot-pass 또는 후속 결정 대상)
```

- [ ] **Step 3: Write skills/blindspot-pass/SKILL.md**

```markdown
---
name: blindspot-pass
description: Use before implementation planning, when starting work in an unfamiliar codebase or domain, or when the user asks what they might be missing ("내가 모르는 게 뭐지") — fans out parallel codebase-scanner agents across four lenses, converts unknown unknowns into concrete decidable questions, resolves them with the user, and writes a Korean unknowns document.
---

# Blindspot Pass

Unknown unknowns are the failures you don't see coming. Concretize them into decidable questions before they become rework.

## Workflow

1. **Collect input.** The task description, plus `docs/blindspot/*-requirements.md` for this topic if it exists — read it; do not re-ask what it already answers.

2. **Fan out scanners.** Spawn `codebase-scanner` agents IN PARALLEL (one message, multiple Agent calls, subagent_type: `codebase-scanner`), one per lens:
   - `conventions`
   - `similar-features`
   - `integration-points`
   - `edge-cases`
   Each agent receives: its lens, the task description, and the requirements doc path if present. Use 3 lenses (drop `similar-features`) when the project is greenfield.

3. **Synthesize.** Merge findings yourself (plain reasoning, no extra agent). For each finding: restate it as a concrete, decidable question ("X를 어떻게 할지", not "X 주의"), assign a quadrant, sort by architecture impact.

4. **Resolve with the user.** Present questions in Korean via AskUserQuestion, architecture-changing first. Questions the findings already answer: decide yourself and mark 자체 해소 with the evidence.

5. **Document.** Follow `templates/unknowns.md` in this skill's folder. Korean. Save to `docs/blindspot/YYYY-MM-DD-<slug>-unknowns.md`.

6. **Verify.** Spawn `doc-verifier` on the file; fix every issue, re-save.

7. **Hand off.** Tell the user (Korean): 설계 문서가 필요하면 `explainer`, 바로 구현이면 `work-report` 노트 모드로.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- Scanners return findings; YOU convert them to questions. A finding without a decision attached is noise.
- Do not serialize the scanner spawns — parallel or it takes 4x longer.
```

- [ ] **Step 4: Write skills/blindspot-pass/templates/unknowns.md**

```markdown
# [주제] Unknown Unknowns

- 날짜: YYYY-MM-DD
- 입력: (requirements 문서 링크, 없으면 "없음")
- 스캔 렌즈: conventions / similar-features / integration-points / edge-cases

## 해소된 항목

| # | 발견 (근거 파일:라인) | 구체화된 질문 | 결정 | 결정 주체 |
|---|---|---|---|---|
| 1 | | | | 사용자 \| 자체 해소 |

## 미해소 항목

| # | 질문 | 보류 이유 | 재방문 시점 |
|---|---|---|---|

## 스캔 원본 요약

### conventions

### similar-features

### integration-points

### edge-cases
```

- [ ] **Step 5: Run check to verify lint passes over new skills**

Run: `bash test/check.sh`
Expected: `OK: all checks passed`

- [ ] **Step 6: Commit**

```bash
git add skills/requirements-interview skills/blindspot-pass
git commit -m "feat: add requirements-interview and blindspot-pass skills

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: explainer + work-report skills (with quiz template)

**Files:**
- Create: `skills/explainer/SKILL.md`
- Create: `skills/explainer/templates/explainer.md`
- Create: `skills/work-report/SKILL.md`
- Create: `skills/work-report/templates/implementation-notes.md`
- Create: `skills/work-report/templates/report.md`
- Create: `skills/work-report/templates/quiz.html`

**Interfaces:**
- Consumes: `doc-verifier`, `change-analyzer` agent names (Task 2); `*-requirements.md` / `*-unknowns.md` patterns (Task 3).
- Produces: `YYYY-MM-DD-<slug>-explainer.md`, `<slug>-implementation-notes.md`, `YYYY-MM-DD-<slug>-report.md`, `quiz/YYYY-MM-DD-<slug>.html`; skill names `explainer`, `work-report` referenced by `blindspot-flow` (Task 5). Quiz template contract: a `const QUESTIONS = [...]` array of `{ q, options, answer }` and a `<!-- SUMMARY -->` block, both replaced by the skill.

- [ ] **Step 1: Write skills/explainer/SKILL.md**

```markdown
---
name: explainer
description: Use when the user asks for a spec, design document, explainer, pitch, or "문서로 정리해줘" — bundles requirements, resolved unknowns, and code reality into one standalone Korean document with decisions, alternatives with trade-offs, and explicit out-of-scope items.
---

# Explainer

One document a zero-context reader can use to understand what is being built, what was decided, and what was deliberately left out.

## Workflow

1. **Gather inputs.** Read `docs/blindspot/*-requirements.md` and `*-unknowns.md` for this topic if they exist; skim the code areas they reference. If neither exists, tell the user and recommend `requirements-interview` or `blindspot-pass` first — never fabricate requirements.

2. **Write.** Follow `templates/explainer.md` in this skill's folder. Korean. The sections that matter most:
   - 검토한 대안과 트레이드오프 — every real decision shows at least one rejected alternative and why
   - 의도적 범위 제외 — mandatory and never empty; if truly nothing was cut, state why the scope is total
   - 열린 질문 — each unresolved item gets an owner or a resolution plan

3. **Save** to `docs/blindspot/YYYY-MM-DD-<slug>-explainer.md`.

4. **Verify.** Spawn `doc-verifier` (subagent_type: `doc-verifier`) on the file; fix every issue, re-save.

5. **Hand off.** Tell the user (Korean): 구현 시작 시 `work-report` 노트 모드로.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- An explainer is not a concatenation of the other two docs; it must stand alone for a reader with zero context.
```

- [ ] **Step 2: Write skills/explainer/templates/explainer.md**

```markdown
# [주제] 설계 문서

- 날짜: YYYY-MM-DD
- 입력: (requirements / unknowns 문서 링크, 없으면 "없음")

## 목적과 배경

## 결정사항

| # | 결정 | 근거 |
|---|---|---|

## 검토한 대안과 트레이드오프

| 결정 | 채택안 | 기각안 | 기각 이유 |
|---|---|---|---|

## 동작 방식

(독자가 코드 없이 이해할 수 있는 수준의 흐름 설명)

## 의도적 범위 제외

- (이번에 일부러 하지 않는 것과 그 이유 — 절대 비워두지 말 것)

## 열린 질문

| 질문 | 해소 계획 |
|---|---|
```

- [ ] **Step 3: Write skills/work-report/SKILL.md**

```markdown
---
name: work-report
description: Use in two modes — (a) notes mode the moment implementation starts and whenever a non-obvious decision or plan deviation happens mid-work: log it immediately; (b) report mode when work completes or before merge: analyze the diff via change-analyzer, write a Korean report with separate Human/Agent sections, and generate a self-contained pre-merge quiz HTML the user must pass before merging.
---

# Work Report

The work is territory; the report is the map you hand back. Keep the map honest while memory is fresh — never reconstructed at the end.

## Notes mode

Trigger: implementation starts, OR you make a non-obvious decision, pick a conservative option on an unexpected edge case, or deviate from the plan.

1. Ensure `docs/blindspot/<slug>-implementation-notes.md` exists — if not, create it from `templates/implementation-notes.md` in this skill's folder.
2. Append one Korean entry per event AT DECISION TIME (not batched later): 결정 / 이유 / 검토한 대안 / 보수적 선택 여부 / 계획과의 이탈 여부.
3. Continue working — notes mode never blocks implementation.

## Report mode

Trigger: work complete, pre-merge, or the user asks for a report.

1. **Analyze.** Spawn `change-analyzer` (subagent_type: `change-analyzer`) with the base ref (default: merge-base with main).
2. **Merge sources.** change-analyzer output + `<slug>-implementation-notes.md` + the explainer/plan if present.
3. **Write the report** following `templates/report.md`, Korean, to `docs/blindspot/YYYY-MM-DD-<slug>-report.md`. Keep the two audiences strictly separate:
   - Human 섹션 — 3–5문장 요약, 스크린샷/데모 자리, 리뷰 포인트(파일:라인)
   - Agent 섹션 — 의도, 제약, 검토한 엣지케이스, 의도적 범위 제외 (structured for a future agent to consume)
4. **Generate the quiz.** Copy `templates/quiz.html` to `docs/blindspot/quiz/YYYY-MM-DD-<slug>.html`; replace the title/summary block and the `QUESTIONS` array with 4–6 Korean multiple-choice questions targeting what a reviewer must understand: 위험 지점, 동작 변화, 계획 이탈, 범위 제외. Wrong options must be plausible.
5. **Gate.** Tell the user (Korean): 퀴즈를 브라우저로 열어 전부 맞히기 전에는 머지하지 말 것. Never declare the work merged/done until the user confirms passing.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- Notes written after the fact are fiction; append at decision time.
- Quiz questions about trivia (file names, line counts) are worthless — ask about behavior and risk.
```

- [ ] **Step 4: Write skills/work-report/templates/implementation-notes.md**

```markdown
# [주제] 구현 노트

- 시작일: YYYY-MM-DD
- 연관 문서: (requirements / unknowns / explainer 링크, 없으면 "없음")

<!-- 결정 시점마다 아래 형식으로 append. 사후 재구성 금지. -->

## YYYY-MM-DD HH:MM — [결정 제목]

- 결정:
- 이유:
- 검토한 대안:
- 보수적 선택 여부: 예/아니오 (예라면 무엇을 미뤘는지)
- 계획과의 이탈: 없음 | (있다면 무엇에서 벗어났는지)
```

- [ ] **Step 5: Write skills/work-report/templates/report.md**

```markdown
# [주제] 작업 보고서

- 날짜: YYYY-MM-DD
- 기준: (base ref) → (HEAD)
- 퀴즈: docs/blindspot/quiz/YYYY-MM-DD-[slug].html — 통과 전 머지 금지

## Human 섹션

### 요약

(3–5문장: 무엇이 어떻게 바뀌었고 사용자에게 어떤 의미인지)

### 스크린샷 / 데모

(UI 변경 시 캡처 자리 — 없으면 "해당 없음")

### 리뷰 포인트

- (리뷰어가 집중해야 할 곳 — 파일:라인)

## Agent 섹션

### 의도 (Intent)

### 제약 (Constraints)

### 검토한 엣지케이스

| 엣지케이스 | 처리 |
|---|---|

### 의도적 범위 제외

### 구현 노트 요약

(implementation-notes에서 이탈·보수적 선택 항목 발췌)
```

- [ ] **Step 6: Write skills/work-report/templates/quiz.html**

```html
<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Pre-Merge Quiz: [주제]</title>
<style>
  body { font-family: sans-serif; max-width: 720px; margin: 2rem auto; padding: 0 1rem; line-height: 1.6; }
  .q { border: 1px solid #ccc; border-radius: 8px; padding: 1rem; margin: 1rem 0; }
  .q.correct { border-color: #2e7d32; background: #edf7ed; }
  .q.wrong { border-color: #c62828; background: #fdecea; }
  #result { font-size: 1.2rem; font-weight: bold; margin: 1rem 0; }
  button { padding: .6rem 1.2rem; font-size: 1rem; cursor: pointer; }
  .summary { background: #f5f5f5; border-radius: 8px; padding: 1rem; }
  label { display: block; }
</style>
</head>
<body>
<h1>Pre-Merge Quiz: [주제]</h1>
<div class="summary">
<h2>변경 요약</h2>
<!-- SUMMARY: work-report가 이 블록을 실제 변경 요약으로 교체 -->
</div>
<h2>퀴즈 — 전부 맞혀야 머지 가능</h2>
<div id="quiz"></div>
<button onclick="grade()">정답 확인</button>
<div id="result"></div>
<script>
// QUESTIONS: work-report가 이 배열을 실제 문항으로 교체한다.
const QUESTIONS = [
  { q: "예시 질문?", options: ["보기 A", "보기 B", "보기 C"], answer: 0 },
];
const quiz = document.getElementById("quiz");
QUESTIONS.forEach((it, i) => {
  const d = document.createElement("div");
  d.className = "q"; d.id = "q" + i;
  d.innerHTML = "<p><b>Q" + (i + 1) + ".</b> " + it.q + "</p>" +
    it.options.map((o, j) =>
      '<label><input type="radio" name="q' + i + '" value="' + j + '"> ' + o + "</label>"
    ).join("");
  quiz.appendChild(d);
});
function grade() {
  let ok = 0;
  QUESTIONS.forEach((it, i) => {
    const sel = document.querySelector('input[name="q' + i + '"]:checked');
    const el = document.getElementById("q" + i);
    const good = sel && Number(sel.value) === it.answer;
    el.className = "q " + (good ? "correct" : "wrong");
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

- [ ] **Step 7: Run check + open quiz template sanity check**

Run: `bash test/check.sh`
Expected: `OK: all checks passed`

Run: `grep -c "QUESTIONS" skills/work-report/templates/quiz.html`
Expected: `5` (comment + declaration + two loops + length check — confirms the replaceable contract exists)

- [ ] **Step 8: Commit**

```bash
git add skills/explainer skills/work-report
git commit -m "feat: add explainer and work-report skills with pre-merge quiz template

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: blindspot-flow orchestrator skill

**Files:**
- Create: `skills/blindspot-flow/SKILL.md`
- Modify: `test/check.sh` (raise lint floor from 3 to 8)

**Interfaces:**
- Consumes: skill names `requirements-interview`, `blindspot-pass`, `explainer`, `work-report` verbatim (Tasks 3–4).
- Produces: skill name `blindspot-flow` (referenced by MANDATE.md from Task 1 — verify the name matches).

- [ ] **Step 1: Write skills/blindspot-flow/SKILL.md**

```markdown
---
name: blindspot-flow
description: Use when the user invokes /blindspot-flow or asks to run a feature through the full lifecycle end-to-end — thin orchestrator that sequences requirements-interview, blindspot-pass, explainer, then work-report notes mode through implementation and report mode at the end.
---

# Blindspot Flow

Thin orchestrator. All real logic lives in the four lifecycle skills — this skill only sequences them.

## Workflow

Run the stages below in order, invoking each with the Skill tool by name. Before each stage, check `docs/blindspot/` for an existing deliverable for this topic; if found, tell the user (Korean) and offer reuse or redo. Between stages, confirm with the user before proceeding — they may stop or skip any stage.

1. `requirements-interview` → requirements doc
2. `blindspot-pass` → unknowns doc
3. `explainer` → design doc
4. `work-report` notes mode opens; implementation proceeds (implementation itself is outside this skill — only note-keeping is enforced)
5. When implementation is done: `work-report` report mode → report + pre-merge quiz

Do not inline a stage's logic here; if a stage needs fixing, fix that skill.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- Skipping a stage is the user's call, not yours — always surface the option, never silently skip.
```

- [ ] **Step 2: Raise the lint floor in test/check.sh**

Change the line:

```bash
[[ ${#files[@]} -ge 3 ]] || fail "expected at least 3 lintable files, got ${#files[@]}"
```

to:

```bash
[[ ${#files[@]} -eq 8 ]] || fail "expected 8 lintable files (5 skills + 3 agents), got ${#files[@]}"
```

- [ ] **Step 3: Run check to verify it passes**

Run: `bash test/check.sh`
Expected: `OK: all checks passed`

Also verify name consistency with the mandate:

Run: `for s in requirements-interview blindspot-pass explainer work-report blindspot-flow; do test -f "skills/$s/SKILL.md" || echo "MISSING $s"; done`
Expected: no output

- [ ] **Step 4: Commit**

```bash
git add skills/blindspot-flow test/check.sh
git commit -m "feat: add blindspot-flow orchestrator skill

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: install.sh with idempotency check

**Files:**
- Create: `install.sh`
- Modify: `test/check.sh` (append section 3 before the final `echo`)

**Interfaces:**
- Consumes: repo layout from Tasks 1–5 (`skills/*/`, `agents/*.md`, `hooks/mandate.sh`, `MANDATE.md`).
- Produces: consumer contract — submodule at `.claude/shared/`, symlinks `.claude/skills/<name>` → `../shared/skills/<name>` and `.claude/agents/<file>` → `../shared/agents/<file>`, hook command string `bash "$CLAUDE_PROJECT_DIR/.claude/shared/hooks/mandate.sh"`, CLAUDE.md line `@.claude/shared/MANDATE.md` (README in Task 7 documents these verbatim).

- [ ] **Step 1: Append failing idempotency check to test/check.sh**

Insert before the final `echo "OK: all checks passed"` line:

```bash
# --- 3. install.sh idempotency (fake consumer project) ---
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/proj/.claude/shared"
cp -a "$ROOT/." "$tmp/proj/.claude/shared/"
(
  cd "$tmp/proj"
  bash .claude/shared/install.sh >/dev/null
  bash .claude/shared/install.sh >/dev/null   # second run must change nothing
  [[ -L .claude/skills/blindspot-pass ]] || { echo "skill symlink missing"; exit 1; }
  [[ -f .claude/skills/blindspot-pass/SKILL.md ]] || { echo "skill symlink broken"; exit 1; }
  [[ -L .claude/agents/codebase-scanner.md ]] || { echo "agent symlink missing"; exit 1; }
  [[ "$(grep -c 'mandate.sh' .claude/settings.json)" == 1 ]] || { echo "hook missing or duplicated"; exit 1; }
  [[ "$(grep -cxF '@.claude/shared/MANDATE.md' CLAUDE.md)" == 1 ]] || { echo "CLAUDE.md import missing or duplicated"; exit 1; }
) || fail "install idempotency check failed"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash test/check.sh`
Expected: `FAIL: install idempotency check failed` (install.sh does not exist yet)

- [ ] **Step 3: Write install.sh**

```bash
#!/usr/bin/env bash
# Consumer onboarding. Run from the consumer project root after:
#   git submodule add <repo-url> .claude/shared
# Idempotent: safe to re-run after submodule updates.
set -euo pipefail

SHARED=".claude/shared"
[[ -d "$SHARED/skills" ]] || { echo "error: run from the consumer project root (needs $SHARED/skills)"; exit 1; }

# 1. symlink skills and agents individually (coexists with project-local ones)
mkdir -p .claude/skills .claude/agents
for d in "$SHARED"/skills/*/; do
  name="$(basename "$d")"
  ln -sfn "../shared/skills/$name" ".claude/skills/$name"
done
for f in "$SHARED"/agents/*.md; do
  name="$(basename "$f")"
  ln -sfn "../shared/agents/$name" ".claude/agents/$name"
done

# 2. merge SessionStart hook into .claude/settings.json
SETTINGS=".claude/settings.json"
HOOK_CMD='bash "$CLAUDE_PROJECT_DIR/.claude/shared/hooks/mandate.sh"'
if command -v jq >/dev/null 2>&1; then
  [[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"
  if ! jq -e --arg cmd "$HOOK_CMD" \
      '.hooks.SessionStart[]?.hooks[]? | select(.command == $cmd)' "$SETTINGS" >/dev/null; then
    tmp="$(mktemp)"
    jq --arg cmd "$HOOK_CMD" \
      '.hooks.SessionStart = ((.hooks.SessionStart // []) + [{"hooks":[{"type":"command","command":$cmd}]}])' \
      "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  fi
elif command -v python3 >/dev/null 2>&1; then
  python3 - "$SETTINGS" "$HOOK_CMD" <<'PY'
import json, os, sys
path, cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)
ss = data.setdefault("hooks", {}).setdefault("SessionStart", [])
if not any(h.get("command") == cmd for e in ss for h in e.get("hooks", [])):
    ss.append({"hooks": [{"type": "command", "command": cmd}]})
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
else
  echo "error: need jq or python3 to merge $SETTINGS."
  echo "Add this to $SETTINGS manually:"
  echo '  {"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash \"$CLAUDE_PROJECT_DIR/.claude/shared/hooks/mandate.sh\""}]}]}}'
  exit 1
fi

# 3. ensure CLAUDE.md imports the mandate
IMPORT_LINE='@.claude/shared/MANDATE.md'
if [[ -f CLAUDE.md ]]; then
  grep -qxF "$IMPORT_LINE" CLAUDE.md || printf '\n%s\n' "$IMPORT_LINE" >> CLAUDE.md
else
  printf '%s\n' "$IMPORT_LINE" > CLAUDE.md
fi

echo "blindspot: installed — skills/agents symlinked, SessionStart hook merged, CLAUDE.md import ensured"
```

Then: `chmod +x install.sh`

- [ ] **Step 4: Run check to verify it passes**

Run: `bash test/check.sh`
Expected: `OK: all checks passed`

- [ ] **Step 5: Commit**

```bash
git add install.sh test/check.sh
git commit -m "feat: add idempotent consumer installer with self-check

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: README, CLAUDE.md rewrite, final check, push

**Files:**
- Create: `README.md`
- Modify: `CLAUDE.md` (full rewrite — current content says the repo is empty, which is now false)

**Interfaces:**
- Consumes: everything — README documents the Task 6 consumer contract verbatim; CLAUDE.md documents `bash test/check.sh` and repo conventions.

- [ ] **Step 1: Write README.md**

```markdown
# dev-env-blindspot

모든 프로젝트가 공통으로 쓰는 Claude Code Agent/Skill 모음 — 사용자 요구사항 이해, Unknown Unknowns 구체화, 문서 작성, 작업사항 보고.

Thariq(Anthropic)의 ["A Field Guide to Fable: Finding Your Unknowns"](https://x.com/trq212/article/2073100352921215386) 라이프사이클과 ["How We Use Skills"](https://x.com/trq212/status/2033949937936085378)의 skill 설계 원칙을 따른다.

## 설치 (소비 프로젝트 루트에서)

```bash
git submodule add https://github.com/dkdlqoddi/dev-env-blindspot.git .claude/shared
bash .claude/shared/install.sh
```

`install.sh`가 하는 일 (멱등 — 재실행 안전):

1. `.claude/skills/`, `.claude/agents/`에 개별 상대 심링크 생성 (프로젝트 자체 skill/agent와 공존)
2. `.claude/settings.json`에 SessionStart hook 병합 — 매 세션 `MANDATE.md`(작업유형→필수 skill 매핑) 주입
3. 프로젝트 `CLAUDE.md`에 `@.claude/shared/MANDATE.md` import 라인 추가 (hook 실패 시 안전망)

## 업데이트

```bash
git submodule update --remote .claude/shared
bash .claude/shared/install.sh
```

## 제공 Skill (라이프사이클 순)

| Skill | 용도 | 산출물 |
|---|---|---|
| `requirements-interview` | 구조화된 인터뷰로 요구사항 확정 (한 번에 한 질문, 아키텍처 영향 순) | `docs/blindspot/YYYY-MM-DD-<slug>-requirements.md` |
| `blindspot-pass` | codebase-scanner 병렬 스캔으로 Unknown Unknowns를 결정 가능한 질문으로 구체화 | `...-unknowns.md` |
| `explainer` | 결정사항·대안·범위 제외를 담은 독립 설계 문서 | `...-explainer.md` |
| `work-report` | (노트) 구현 중 결정 즉시 기록 / (보고) diff 분석 + Human/Agent 분리 보고서 + Pre-Merge Quiz | `...-report.md`, `quiz/*.html`, `<slug>-implementation-notes.md` |
| `blindspot-flow` | 위 전체를 순서대로 실행하는 오케스트레이터 (`/blindspot-flow`) | (하위 skill 산출물) |

## 제공 Agent (모두 읽기 전용)

| Agent | 역할 |
|---|---|
| `codebase-scanner` | 렌즈(conventions/similar-features/integration-points/edge-cases)별 코드 탐색, `파일:라인` 근거 반환 |
| `doc-verifier` | 산출 문서의 placeholder·모순·모호성·범위 검사 |
| `change-analyzer` | base 대비 diff 분석: 변경 요약, 위험 지점, 테스트 유무, 퀴즈 후보 |

## 규칙

- 산출물은 전부 한국어, `docs/blindspot/` 아래에 저장
- Pre-Merge Quiz를 전부 맞히기 전에는 머지 금지

## 제약

- 심링크 사용: Linux / WSL / macOS 전용 (네이티브 Windows 미지원)
- settings 병합에 `jq` 또는 `python3` 필요

## 이 저장소 개발

```bash
bash test/check.sh   # mandate hook + frontmatter lint + installer 멱등성
```

설계 문서: `docs/superpowers/specs/`, 구현 계획: `docs/superpowers/plans/`
```

- [ ] **Step 2: Rewrite CLAUDE.md**

Replace the entire file content with:

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Shared Claude Code skills/agents that other projects consume as a git submodule mounted at `.claude/shared/`, wired up by `install.sh` (individual relative symlinks into `.claude/skills` and `.claude/agents`, a SessionStart hook running `hooks/mandate.sh`, and a `@.claude/shared/MANDATE.md` import in the consumer's CLAUDE.md). It implements Thariq's "Finding Your Unknowns" lifecycle: `requirements-interview` → `blindspot-pass` → `explainer` → `work-report`, orchestrated by `blindspot-flow`.

## Test

```bash
bash test/check.sh
```

Covers: mandate hook output names all 5 skills, YAML frontmatter lint (`name`, `description`) across exactly 8 files (5 skills + 3 agents), and `install.sh` idempotency against a fake consumer project in a temp dir (run twice, assert symlinks/settings/CLAUDE.md unchanged).

## Conventions

- Model-facing instruction files (`SKILL.md`, `agents/*.md`, `MANDATE.md`): English. User-facing deliverables the skills generate: Korean. Do not mix.
- Skill frontmatter `description` is the trigger condition — always "Use when ...".
- Every SKILL.md has a `## Gotchas` section. Append recurring failure points there; never delete entries or create separate gotcha docs.
- Agents are read-only by design — keep `tools` minimal (`Bash` only where git inspection is required, with read-only instructions in the body).
- Deliverable path contract baked into skills: `docs/blindspot/YYYY-MM-DD-<slug>-{requirements,unknowns,explainer,report}.md`, `docs/blindspot/quiz/*.html`, `docs/blindspot/<slug>-implementation-notes.md` (no date prefix).

## Consumer contract (breaking-change checklist)

Renaming or moving any of these breaks consumer projects — update `install.sh` + `test/check.sh` + `README.md` together:

- `skills/<name>/` directory names (= installed skill names, referenced in `MANDATE.md`)
- `agents/*.md` filenames (= `subagent_type` values referenced inside SKILL.md files)
- `hooks/mandate.sh`, `MANDATE.md` paths (referenced by consumer `settings.json` and CLAUDE.md import line)

## Design docs

Spec: `docs/superpowers/specs/2026-07-06-blindspot-agents-skills-design.md`. Plan: `docs/superpowers/plans/2026-07-06-blindspot-agents-skills.md`.
```

- [ ] **Step 3: Final full check**

Run: `bash test/check.sh`
Expected: `OK: all checks passed`

- [ ] **Step 4: Commit and push**

```bash
git add README.md CLAUDE.md
git commit -m "docs: add consumer README and rewrite CLAUDE.md for implemented repo

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
git push origin main
```

Expected: push succeeds to `origin/main`.

---

## Plan Self-Review Notes

- Spec coverage: §3 layout → Tasks 1–7; §4.1–4.5 skills → Tasks 3–5; §5 agents → Task 2; §6 enforcement → Task 1 (+ install wiring Task 6); §7 onboarding → Task 6; §8 verification → check.sh grown across Tasks 1/2/6; §9 exclusions honored (no marketplace, no per-prompt hooks, no telemetry, no CI).
- Name consistency verified: 5 skill names identical across MANDATE.md (Task 1), SKILL.md frontmatter (Tasks 3–5), check.sh loop (Task 1), README table (Task 7); 3 agent names identical across agent frontmatter (Task 2), SKILL.md subagent_type references (Tasks 3–4), check.sh symlink assert (Task 6).
- Deliverable filename patterns identical in skills, MANDATE.md, README, CLAUDE.md.
```
