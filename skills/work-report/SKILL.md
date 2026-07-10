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
3. Continue working — notes mode never blocks implementation.

## Report mode

Trigger: work complete, pre-merge, or the user asks for a report.

1. **Analyze.** Spawn `change-analyzer` (subagent_type: `change-analyzer`) with the base ref (default: merge-base with main).
2. **Merge sources.** change-analyzer output + `<slug>-implementation-notes.md` + the explainer/plan if present.
3. **Write the report** following `templates/report.md`, Korean, to `docs/blindspot/YYYY-MM-DD-<slug>-report.md`. Keep the two audiences strictly separate:
   - Human 섹션 — 3–5문장 요약, 스크린샷/데모 자리, 리뷰 포인트(파일:라인). The 요약 is read by non-developers: apply the sentence rules from step 4 to it — what happened and what it means for users, never how the code looks; no code syntax, identifiers, file paths, or arrow shorthand; unavoidable technical terms plain Korean first with the term in parentheses. 리뷰 포인트 is for code reviewers — keep it technical; 파일:라인 references are its job.
   - Agent 섹션 — 의도, 제약, 검토한 엣지케이스, 의도적 범위 제외 (structured for a future agent to consume; technical language is correct here — do not simplify it)
4. **Generate the quiz.** Copy `templates/quiz.html` to `docs/blindspot/quiz/YYYY-MM-DD-<slug>.html`; replace the title/summary block and the `QUESTIONS` array with 4–6 Korean multiple-choice questions targeting what a reviewer must understand: 위험 지점, 동작 변화, 계획 이탈, 범위 제외. Wrong options must be plausible. The quiz reader is a non-developer — write every sentence for someone who has never seen the code:
   - Ask what happens or what could go wrong, never how the code looks. No code syntax, identifiers, file paths, or shell fragments inside question or option sentences; no arrow shorthand (A→B); no unexplained jargon.
   - Unavoidable technical terms: plain Korean first, term in parentheses — e.g. "설정 파일이 깨져 있으면(잘못된 JSON)".
   - A question is one short scenario sentence plus one question sentence. Options are complete sentences, one idea each, similar length and form — a conspicuously long option must not give away the answer.
   - Every question gets an `explain` field: 2–3 plain Korean sentences on why the answer is right and why the most tempting wrong option is wrong. Technical terms and file paths belong here (in parentheses), not in questions.
   - The summary block follows the same rules: user-visible changes only, no commit hashes, no arrows.
   - Before saving, self-check every sentence: could someone who has never seen code tell what is being asked? If not, rewrite it.
5. **Gate.** Tell the user (Korean): 퀴즈를 브라우저로 열어 전부 맞히기 전에는 머지하지 말 것. Never declare the work merged/done until the user confirms passing.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- Notes written after the fact are fiction; append at decision time.
- Quiz questions about trivia (file names, line counts) are worthless — ask about behavior and risk.
- A quiz written in the author's head-language (code syntax, arrows, compressed jargon) locks out non-developers; every sentence must survive the "reader has never seen the code" test.
- A 요약 written in engineer-speak (arrows, raw jargon) locks stakeholders out — but only the 요약: 리뷰 포인트 and the Agent 섹션 are technical by design; simplifying them destroys their function.
