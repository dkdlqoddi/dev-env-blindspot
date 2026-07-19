---
name: work-report
description: "Use in two modes — (a) notes mode the moment implementation starts and whenever a non-obvious decision or plan deviation happens mid-work: log it immediately; (b) report mode when work completes or before merge: analyze the diff via change-analyzer, write a Korean report with separate Human/Agent sections, and generate a self-contained pre-merge quiz HTML the user must pass before merging."
---

# Work Report

The work is territory; the report is the map you hand back. Keep the map honest while memory is fresh — never reconstructed at the end.

## Notes mode

Trigger: implementation starts, OR you make a non-obvious decision, pick a conservative option on an unexpected edge case, or deviate from the plan.

1. Ensure `docs/blindspot/<slug>-implementation-notes.md` exists — if not, create it from `templates/implementation-notes.md` in this skill's folder.
2. Append one Korean entry per event AT DECISION TIME (not batched later): 결정 / 이유 / 검토한 대안 / 보수적 선택 여부 / 계획과의 이탈 여부.
3. A decision that seems to need user input: if it is reversible, take the conservative option, log it, and mark it 사용자 확인 필요 for the next checkpoint (stage boundary or report mode) instead of asking mid-flow. Ask immediately only when the choice is irreversible or destructive (data loss, external side effects, published contracts).
4. Continue working — notes mode never blocks implementation.

## Report mode

Trigger: work complete, pre-merge, or the user asks for a report.

1. **Analyze.** Spawn `change-analyzer` (subagent_type: `change-analyzer`) with the base ref (default: merge-base with the default branch — main, else master).
2. **Merge sources.** change-analyzer output + `<slug>-implementation-notes.md` + the explainer/plan if present.
3. **Write the report** following `templates/report.md`, Korean, to `docs/blindspot/YYYY-MM-DD-<slug>-report.md`. Keep the two audiences strictly separate:
   - Human 섹션 — 3–5문장 요약, 스크린샷/데모 자리, 리뷰 포인트(파일:라인). The 요약 is read by non-developers: apply the sentence rules from step 4 to it — one fact per sentence, ≤25 어절 each, split anything longer; what happened and what it means for users, never how the code looks; no code syntax, identifiers, file paths, or arrow shorthand; unavoidable technical terms plain Korean first with the term in parentheses. 리뷰 포인트 is for code reviewers — keep it technical; 파일:라인 references are its job.
   - Agent 섹션 — 의도, 제약, 검토한 엣지케이스, 의도적 범위 제외 (structured for a future agent to consume; technical language is correct here — do not simplify it)
4. **Generate the quiz.** Copy `templates/quiz.html` to `docs/blindspot/quiz/YYYY-MM-DD-<slug>.html`; replace the title/summary block and the `QUESTIONS` array with 4–6 Korean multiple-choice questions targeting what a reviewer must understand: 위험 지점, 동작 변화, 계획 이탈, 범위 제외. Wrong options must be plausible. The quiz reader is a non-developer — write every sentence for someone who has never seen the code:
   - Ask what happens or what could go wrong, never how the code looks. No code syntax, identifiers, file paths, or shell fragments inside question or option sentences; no arrow shorthand (A→B); no unexplained jargon.
   - Unavoidable technical terms: plain Korean first, term in parentheses — e.g. "설정 파일이 깨져 있으면(잘못된 JSON)".
   - The quiz is a self-contained gate, not an exam: the 변경 요약 plus the question's own scenario sentence must contain every fact needed to answer. Never quiz recall of report internals or process history (which step, review, or commit did what); ask the reader to apply a summary fact — what changes for users, what could go wrong, what was deliberately not done.
   - A question is one scenario sentence plus one question sentence — one fact each, ≤25 어절 per sentence. Options are complete sentences, one idea each, ≤40 Korean characters, parallel in form — a conspicuously long option must not give away the answer. Vary the correct answer's position across questions.
   - Every question gets an `explain` field: 2–3 plain Korean sentences (same ≤25 어절 bar) on why the answer is right and why the most tempting wrong option is wrong. Technical terms and file paths belong here (in parentheses), not in questions.
   - The summary block follows the same sentence rules: user-visible changes only, no commit hashes, no arrows — and it must state every fact the questions rely on.
   - Before saving, self-check every question: could someone who read only the 변경 요약 answer it? Is every sentence one fact within 25 어절, every option within 40 characters? If not, rewrite.
5. **Gate.** First present any 사용자 확인 필요 items queued in the implementation notes as batched Korean questions — their answers may amend the report. Then tell the user (Korean): 퀴즈를 브라우저로 열어 전부 맞히기 전에는 머지하지 말 것. Never declare the work merged/done until the user confirms passing.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- Notes written after the fact are fiction; append at decision time.
- Quiz questions about trivia (file names, line counts) are worthless — ask about behavior and risk.
- A quiz written in the author's head-language (code syntax, arrows, compressed jargon) locks out non-developers; every sentence must survive the "reader has never seen the code" test.
- A 요약 written in engineer-speak (arrows, raw jargon) locks stakeholders out — but only the 요약: 리뷰 포인트 and the Agent 섹션 are technical by design; simplifying them destroys their function.
- Clean vocabulary does not equal readable: a 40+ 어절 sentence with nested clauses locks out the same readers even with zero jargon — the one-fact / ≤25 어절 bar is part of the standard.
- A quiz that needs report-internals recall is an exam, not a gate; if the 변경 요약 cannot support the answer, fix the summary or drop the question.
- Stopping mid-work to ask about a reversible choice trades flow for false safety — conservative default + note + checkpoint batch keeps the decision visible without blocking. Immediate questions are reserved for irreversible or destructive choices.
