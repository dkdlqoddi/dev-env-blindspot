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
