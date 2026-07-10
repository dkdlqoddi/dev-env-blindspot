# Requirements/Unknowns Readability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the non-developer readability standard to the two remaining lifecycle deliverables — requirements docs (whole document + live interview questions) and unknowns docs (질문·결정·보류 이유 columns only; evidence and scan summaries stay technical) — per the approved spec at `docs/superpowers/specs/2026-07-10-requirements-unknowns-readability-design.md`.

**Architecture:** Pure content changes, no new files, one task. Rules live inline in each SKILL.md (self-contained, matching the two prior readability cycles). One template placeholder update (requirements.md); `templates/unknowns.md` deliberately unchanged (spec §2 — no placeholder slot in its table structure; SKILL.md step 5 carries the rule). No validation sample exists to regenerate (this repo has no requirements/unknowns deliverables).

**Tech Stack:** Markdown only (2 SKILL.md files, 1 template), bash (`test/check.sh`). No browser verification.

## Global Constraints

- Model-facing instruction files are **English** (Korean fragments where the spec shows them — transcribe verbatim); template placeholder text is **Korean**. Do not mix. (CLAUDE.md)
- `## Gotchas` sections: append only, never delete or reorder existing entries. (CLAUDE.md)
- No files added or removed under `skills/*/SKILL.md` or `agents/*.md` — `test/check.sh` asserts exactly 9. (spec §4)
- Audience split (spec §2): requirements = whole document + interview questions/options; unknowns = 구체화된 질문·결정·보류 이유 columns only, with 발견/근거 columns and 스캔 원본 요약 explicitly kept technical ("do not simplify it").
- `skills/blindspot-pass/templates/unknowns.md` must NOT change. (spec §2/§5)
- Exactly 3 files may change: `skills/requirements-interview/SKILL.md`, `skills/requirements-interview/templates/requirements.md`, `skills/blindspot-pass/SKILL.md`.
- Commit messages end with:
  `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- Do NOT push — the push happens after the final whole-branch review (controller step).

---

### Task 1: Readability rules in requirements-interview and blindspot-pass

**Files:**
- Modify: `skills/requirements-interview/SKILL.md` (Workflow steps 3–4; Gotchas)
- Modify: `skills/requirements-interview/templates/requirements.md` (요청 배경 placeholder, line 9)
- Modify: `skills/blindspot-pass/SKILL.md` (Workflow steps 3–5; Gotchas)

**Interfaces:**
- Consumes: nothing from other tasks (single-task plan). The rule phrasing mirrors the standard already in `skills/work-report/SKILL.md` and `skills/explainer/SKILL.md` — do not edit those files.
- Produces: n/a (final task).

- [ ] **Step 1: Add the question-wording bullet to step 3 of `skills/requirements-interview/SKILL.md`**

Replace this exact block:

```markdown
3. **Interview.** In Korean, ONE question per message, via AskUserQuestion with 2–4 concrete options where possible.
   - Order by architecture impact: answers that change the design come first.
   - Stop when remaining answers would no longer change what you'd build (typically 3–6 questions).
   - Record every question, answer, and its architecture impact.
```

with:

```markdown
3. **Interview.** In Korean, ONE question per message, via AskUserQuestion with 2–4 concrete options where possible.
   - Write every question and option for someone who has never seen the code: unavoidable technical terms plain Korean first with the term in parentheses; code identifiers only after a plain description of what they do.
   - Order by architecture impact: answers that change the design come first.
   - Stop when remaining answers would no longer change what you'd build (typically 3–6 questions).
   - Record every question, answer, and its architecture impact.
```

- [ ] **Step 2: Replace step 4 of `skills/requirements-interview/SKILL.md`**

Replace this exact line:

```markdown
4. **Write the document.** Follow `templates/requirements.md` in this skill's folder. Fill every section in Korean. Save to `docs/blindspot/YYYY-MM-DD-<slug>-requirements.md` (slug = kebab-case topic, date = today).
```

with:

```markdown
4. **Write the document.** Follow `templates/requirements.md` in this skill's folder. Fill every section in Korean, for a reader who has never seen the code: no arrow shorthand (A→B) or unexplained jargon; unavoidable technical terms plain Korean first with the term in parentheses. Evidence links and 관련 문서 paths stay as they are. Before saving, self-check every sentence: could someone who has never seen code follow it? Save to `docs/blindspot/YYYY-MM-DD-<slug>-requirements.md` (slug = kebab-case topic, date = today).
```

- [ ] **Step 3: Append the requirements-interview Gotchas entry**

In the same file's `## Gotchas` list, append after the last entry (`- One decision per question. Batched questions get half-answers.`):

```markdown
- A question the user cannot parse gets a guessed answer; guessed answers become wrong requirements. Every question and every document sentence must survive the "reader has never seen the code" test.
```

- [ ] **Step 4: Update the 요청 배경 placeholder in `skills/requirements-interview/templates/requirements.md`**

Replace this exact line:

```markdown
(사용자가 이 요청을 하게 된 맥락 1–3문장)
```

with:

```markdown
(사용자가 이 요청을 하게 된 맥락 1–3문장 — 문서 전체: 코드를 본 적 없는 독자 기준, 전문용어는 쉬운 말 먼저(용어 병기), 화살표 축약 금지)
```

- [ ] **Step 5: Replace step 3 of `skills/blindspot-pass/SKILL.md`**

Replace this exact block:

```markdown
3. **Synthesize.** Merge findings yourself (plain reasoning, no extra agent). For each finding: restate it as a concrete, decidable question ("X를 어떻게 할지", not "X 주의"), assign a quadrant, sort by architecture impact. Keep evidence attached — `file:line` for code findings, source URL for domain findings.
```

with:

```markdown
3. **Synthesize.** Merge findings yourself (plain reasoning, no extra agent). For each finding: restate it as a concrete, decidable question ("X를 어떻게 할지", not "X 주의") written for someone who has never seen the code — unavoidable technical terms plain Korean first with the term in parentheses, code identifiers only after a plain description. Assign a quadrant, sort by architecture impact. Keep evidence attached — `file:line` for code findings, source URL for domain findings; evidence stays technical.
```

- [ ] **Step 6: Replace step 4 of `skills/blindspot-pass/SKILL.md`**

Replace this exact block:

```markdown
4. **Resolve with the user.** Present questions in Korean via AskUserQuestion, architecture-changing first. If domain findings exist, open with a short primer (5–10 lines in Korean, from the researcher's 핵심 개념) — the user must understand the concepts to answer the questions. Questions the findings already answer: decide yourself and mark 자체 해소 with the evidence.
```

with:

```markdown
4. **Resolve with the user.** Present questions in Korean via AskUserQuestion, architecture-changing first. Questions, options, and the primer follow the same non-developer bar as step 3. If domain findings exist, open with a short primer (5–10 lines in Korean, from the researcher's 핵심 개념) — the user must understand the concepts to answer the questions. Questions the findings already answer: decide yourself and mark 자체 해소 with the evidence.
```

- [ ] **Step 7: Replace step 5 of `skills/blindspot-pass/SKILL.md`**

Replace this exact block:

```markdown
5. **Document.** Follow `templates/unknowns.md` in this skill's folder. Korean. Save to `docs/blindspot/YYYY-MM-DD-<slug>-unknowns.md`. Omit lenses that did not run from the 스캔 렌즈 line and drop their `### <lens>` sections (greenfield drops `similar-features`; code-only tasks drop `domain`).
```

with:

```markdown
5. **Document.** Follow `templates/unknowns.md` in this skill's folder. Korean. The 구체화된 질문, 결정, and 보류 이유 columns are read by non-developers — apply the step 3 sentence bar to them. The 발견/근거 columns and the 스캔 원본 요약 sections are technical evidence for later stages — technical language is correct there; do not simplify it. Save to `docs/blindspot/YYYY-MM-DD-<slug>-unknowns.md`. Omit lenses that did not run from the 스캔 렌즈 line and drop their `### <lens>` sections (greenfield drops `similar-features`; code-only tasks drop `domain`).
```

- [ ] **Step 8: Append the blindspot-pass Gotchas entry**

In `skills/blindspot-pass/SKILL.md`'s `## Gotchas` list, append after the last entry (`- Domain unknowns don't live in the repo — ...`):

```markdown
- A concretized question the user cannot parse defeats the whole pass — the decision gets guessed, not made. Questions and decisions in plain Korean; evidence and scan summaries stay technical.
```

- [ ] **Step 9: Verify `templates/unknowns.md` is untouched and run the repo check**

Run: `git status --porcelain skills/blindspot-pass/templates/unknowns.md`
Expected: no output (file unchanged).

Run: `bash test/check.sh`
Expected: `OK: all checks passed` (frontmatter untouched, file count still 9).

- [ ] **Step 10: Commit (no push)**

```bash
git add skills/requirements-interview/SKILL.md skills/requirements-interview/templates/requirements.md skills/blindspot-pass/SKILL.md
git commit -m "feat: non-developer readability rules for requirements interview and blindspot pass

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

The push to `origin main` happens after the final whole-branch review (controller step), not in this task.
