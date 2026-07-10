# Report/Explainer Readability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the non-developer readability standard to the work-report Human 요약 (per-section audience rules) and the entire explainer, and rewrite the existing 2026-07-06 report's 요약 as the validation sample — per the approved spec at `docs/superpowers/specs/2026-07-10-report-explainer-readability-design.md`.

**Architecture:** Pure content changes, no new files. Rules live inline in each SKILL.md (work-report step 3 references its own step 4 rule list; explainer carries its own condensed rules for self-containment). Template placeholders carry the Korean hint and are consumed at generation time. The rewritten 요약 is the end-to-end validation sample.

**Tech Stack:** Markdown only (SKILL.md, templates, one deliverable doc), bash (`test/check.sh`, awk/grep scan). No browser verification (no HTML touched).

## Global Constraints

- Model-facing instruction files are **English** (Korean fragments where the spec shows them — transcribe verbatim); deliverables and template placeholder text are **Korean**. Do not mix. (CLAUDE.md)
- `## Gotchas` sections: append only, never delete or reorder existing entries. (CLAUDE.md)
- No files added or removed under `skills/*/SKILL.md` or `agents/*.md` — `test/check.sh` asserts exactly 9. (spec §4)
- Per-section audience rule (spec §2): 요약 = non-developer; 리뷰 포인트 = code reviewers (파일:라인 stays); Agent 섹션 = future agent (technical language stays). Only the 요약 gets the non-developer bar in the report.
- In `docs/blindspot/2026-07-06-blindspot-agents-skills-report.md`, ONLY the `### 요약` body paragraph changes — everything else byte-identical, including the acceptance-record meta lines and the `기준: dc45220 (초기 커밋) → a8e8740 (HEAD)` line (metadata, spec §5). (spec §3.5)
- Commit after every task. Commit messages end with:
  `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- Do NOT push in any task — the push happens after the final whole-branch review (controller step).

---

### Task 1: Readability rules in both skills + template placeholders

**Files:**
- Modify: `skills/work-report/SKILL.md` (Report mode step 3; Gotchas)
- Modify: `skills/work-report/templates/report.md` (요약 placeholder, line 11)
- Modify: `skills/explainer/SKILL.md` (Workflow step 2; Gotchas)
- Modify: `skills/explainer/templates/explainer.md` (목적과 배경 placeholder)

**Interfaces:**
- Consumes: the sentence-rule list already in `skills/work-report/SKILL.md` step 4 (added by the quiz-readability plan) — step 3's new text references it as "the sentence rules from step 4"; do not duplicate the list.
- Produces: the rule text that Task 2's rewritten 요약 must satisfy.

- [ ] **Step 1: Replace step 3 of Report mode in `skills/work-report/SKILL.md`**

Replace this exact block:

```markdown
3. **Write the report** following `templates/report.md`, Korean, to `docs/blindspot/YYYY-MM-DD-<slug>-report.md`. Keep the two audiences strictly separate:
   - Human 섹션 — 3–5문장 요약, 스크린샷/데모 자리, 리뷰 포인트(파일:라인)
   - Agent 섹션 — 의도, 제약, 검토한 엣지케이스, 의도적 범위 제외 (structured for a future agent to consume)
```

with:

```markdown
3. **Write the report** following `templates/report.md`, Korean, to `docs/blindspot/YYYY-MM-DD-<slug>-report.md`. Keep the two audiences strictly separate:
   - Human 섹션 — 3–5문장 요약, 스크린샷/데모 자리, 리뷰 포인트(파일:라인). The 요약 is read by non-developers: apply the sentence rules from step 4 to it — what happened and what it means for users, never how the code looks; no code syntax, identifiers, file paths, or arrow shorthand; unavoidable technical terms plain Korean first with the term in parentheses. 리뷰 포인트 is for code reviewers — keep it technical; 파일:라인 references are its job.
   - Agent 섹션 — 의도, 제약, 검토한 엣지케이스, 의도적 범위 제외 (structured for a future agent to consume; technical language is correct here — do not simplify it)
```

- [ ] **Step 2: Append the work-report Gotchas entry**

In the same file's `## Gotchas` list, append after the last entry (`- A quiz written in the author's head-language ...`):

```markdown
- A 요약 written in engineer-speak (arrows, raw jargon) locks stakeholders out — but only the 요약: 리뷰 포인트 and the Agent 섹션 are technical by design; simplifying them destroys their function.
```

- [ ] **Step 3: Update the 요약 placeholder in `skills/work-report/templates/report.md`**

Replace this exact line:

```markdown
(3–5문장: 무엇이 어떻게 바뀌었고 사용자에게 어떤 의미인지)
```

with:

```markdown
(3–5문장, 코드를 본 적 없는 사람 기준: 무엇이 어떻게 바뀌었고 사용자에게 어떤 의미인지. 화살표 축약·미풀이 전문용어 금지, 불가피한 용어는 쉬운 말 먼저(용어 병기))
```

- [ ] **Step 4: Replace step 2 of Workflow in `skills/explainer/SKILL.md`**

Replace this exact block:

```markdown
2. **Write.** Follow `templates/explainer.md` in this skill's folder. Korean. The sections that matter most:
   - 검토한 대안과 트레이드오프 — every real decision shows at least one rejected alternative and why
   - 의도적 범위 제외 — mandatory and never empty; if truly nothing was cut, state why the scope is total
   - 열린 질문 — each unresolved item gets an owner or a resolution plan
```

with:

```markdown
2. **Write.** Follow `templates/explainer.md` in this skill's folder. Korean. The entire document is for a reader who has never seen the code:
   - Describe what happens and why, never how the code looks. No arrow shorthand (A→B), no unexplained jargon; unavoidable technical terms plain Korean first with the term in parentheses — e.g. "설정 파일이 깨져 있으면(잘못된 JSON)".
   - Code identifiers and file paths appear only where they are the subject being explained, introduced by a plain description.
   - Before saving, self-check every sentence: could someone who has never seen code follow it? If not, rewrite it.

   The sections that matter most:
   - 검토한 대안과 트레이드오프 — every real decision shows at least one rejected alternative and why
   - 의도적 범위 제외 — mandatory and never empty; if truly nothing was cut, state why the scope is total
   - 열린 질문 — each unresolved item gets an owner or a resolution plan
```

- [ ] **Step 5: Append the explainer Gotchas entry**

In `skills/explainer/SKILL.md`'s `## Gotchas` list, append after the last entry (`- An explainer is not a concatenation ...`):

```markdown
- An explainer that reads like an engineering changelog fails its zero-context purpose; every sentence must survive the "reader has never seen the code" test.
```

- [ ] **Step 6: Add the placeholder in `skills/explainer/templates/explainer.md`**

Directly under the `## 목적과 배경` heading (currently followed by a blank line then `## 결정사항`), insert:

```markdown
(코드를 본 적 없는 독자가 이 문서만으로 처음부터 끝까지 읽을 수 있게 — 전문용어는 쉬운 말 먼저(용어 병기), 화살표 축약 금지)
```

so the section reads:

```markdown
## 목적과 배경

(코드를 본 적 없는 독자가 이 문서만으로 처음부터 끝까지 읽을 수 있게 — 전문용어는 쉬운 말 먼저(용어 병기), 화살표 축약 금지)

## 결정사항
```

- [ ] **Step 7: Run the repo check**

Run: `bash test/check.sh`
Expected: `OK: all checks passed` (frontmatter untouched, file count still 9).

- [ ] **Step 8: Commit**

```bash
git add skills/work-report/SKILL.md skills/work-report/templates/report.md skills/explainer/SKILL.md skills/explainer/templates/explainer.md
git commit -m "feat: non-developer readability rules for report 요약 and explainer

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: Rewrite the existing report's 요약 (validation sample)

**Files:**
- Modify: `docs/blindspot/2026-07-06-blindspot-agents-skills-report.md` (the `### 요약` body paragraph ONLY)

**Interfaces:**
- Consumes: sentence rules from Task 1 (the rewritten text below already satisfies them — transcribe verbatim).
- Produces: the validation sample. The acceptance record (meta lines), 리뷰 포인트, and Agent 섹션 stay byte-identical.

- [ ] **Step 1: Replace the 요약 paragraph**

In `docs/blindspot/2026-07-06-blindspot-agents-skills-report.md`, under `### 요약`, replace this exact paragraph:

```markdown
빈 저장소 위에 모든 프로젝트가 공유하는 Claude Code Agent/Skill 저장소를 처음부터 구축했다. Thariq의 "Finding Your Unknowns" 라이프사이클을 skill 5종(requirements-interview → blindspot-pass → explainer → work-report, 그리고 전체를 잇는 blindspot-flow)과 읽기 전용 agent 3종으로 구현했고, 소비 프로젝트는 submodule + `install.sh` 한 번으로 심링크·SessionStart hook·CLAUDE.md import가 자동 연결된다. 실행 코드는 bash 스크립트 3개뿐이며 나머지는 전부 모델/사용자 대상 문서다. 태스크별 리뷰 7회 + 최종 전체 리뷰 + 수정 재리뷰를 모두 통과했고 `test/check.sh`가 멱등성까지 검증한다.
```

with:

```markdown
아무것도 없던 빈 저장소를, 여러 프로젝트가 함께 가져다 쓰는 AI 작업 도구 모음으로 처음부터 만들었다. 도구는 두 종류다 — 작업을 단계별 절차로 이끄는 도구 다섯 가지(요구사항 인터뷰, 사각지대 점검, 설명 문서 작성, 작업 보고, 그리고 이 네 단계를 순서대로 진행해 주는 진행 도구), 그리고 조사·검증을 대신해 주는 읽기 전용 보조 조사원 세 가지다. 다른 프로젝트는 설치 프로그램을 한 번 실행하면 연결되고, 그 뒤로는 작업 세션이 시작될 때마다 '작업 유형별 필수 절차' 규칙이 AI에게 자동으로 전달된다. 실제로 실행되는 코드는 작은 스크립트 세 개뿐이고, 나머지는 전부 AI와 사람이 읽는 문서다. 단계마다 검토를 일곱 번, 마지막에 전체 검토까지 거쳤고, 자동 점검이 문서 형식부터 '설치를 두 번 해도 결과가 같은가(멱등성)'까지 검사한다.
```

Nothing else in the file changes — not the meta lines (including `기준: dc45220 (초기 커밋) → a8e8740 (HEAD)` and the 퀴즈 통과 완료 line), not 리뷰 포인트, not the Agent 섹션.

- [ ] **Step 2: Scoped mechanical scan of the rewritten 요약**

Run:
```bash
awk '/^### 요약/{f=1;next} /^###/{f=0} f' docs/blindspot/2026-07-06-blindspot-agents-skills-report.md | grep -nE '→|\$\{|\[\[|`'
```
Expected: no output, exit code 1 — no arrows, shell fragments, or backtick code spans in the 요약 block. (Arrows elsewhere in the file — meta line, Agent 섹션 — are legitimate and out of scan scope.)

Then verify the rest of the file is untouched:
```bash
git diff --stat -- docs/blindspot/2026-07-06-blindspot-agents-skills-report.md
```
Expected: exactly 1 file changed, and `git diff` shows only the one paragraph swapped (1 hunk).

- [ ] **Step 3: Run the repo check**

Run: `bash test/check.sh`
Expected: `OK: all checks passed`

- [ ] **Step 4: Commit (no push)**

```bash
git add docs/blindspot/2026-07-06-blindspot-agents-skills-report.md
git commit -m "docs: rewrite 2026-07-06 report 요약 for non-developer readers

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

The push to `origin main` happens after the final whole-branch review (controller step), not in this task.
