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
