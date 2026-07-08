---
name: blindspot-pass
description: Use when starting work in an unfamiliar codebase or domain, before writing an implementation plan, or when the user asks what they might be missing ("내가 모르는 게 뭐지") — fans out parallel codebase-scanner agents across four lenses (plus a domain-researcher for knowledge outside the codebase), converts unknown unknowns into concrete decidable questions, resolves them with the user, and writes a Korean unknowns document.
---

# Blindspot Pass

Unknown unknowns are the failures you don't see coming. Concretize them into decidable questions before they become rework.

## Workflow

1. **Collect input and classify territory.** The task description, plus `docs/blindspot/*-requirements.md` for this topic if it exists — read it; do not re-ask what it already answers. Split the unfamiliarity into two territories: code (this repository) and domain (knowledge living outside the codebase — e.g. color grading, payment standards). A task can have both.

2. **Fan out scanners.** If `codebase-scanner` is not yet defined, use the `define_subagent` tool with the instructions from `.agents/plugins/dev-env-blindspot/agents/codebase-scanner.md`. Then spawn them IN PARALLEL using `invoke_subagent` (one call with multiple entries), one per lens:
   - `conventions`
   - `similar-features`
   - `integration-points`
   - `edge-cases`
   Each agent receives: its lens, the task description, and the requirements doc path if present. Use 3 lenses (drop `similar-features`) when the project is greenfield; skip the codebase lenses entirely only when the task touches no code.

   If domain territory exists, define it (via `define_subagent` from `.agents/plugins/dev-env-blindspot/agents/domain-researcher.md`) and add ONE `domain-researcher` agent to the same parallel `invoke_subagent` batch, with: the domain topic, the task description, and what the user already knows.

3. **Synthesize.** Merge findings yourself (plain reasoning, no extra agent). For each finding: restate it as a concrete, decidable question ("X를 어떻게 할지", not "X 주의"), assign a quadrant, sort by architecture impact. Keep evidence attached — `file:line` for code findings, source URL for domain findings.

4. **Resolve with the user.** Present questions in Korean using the `ask_question` tool, architecture-changing first. If domain findings exist, open with a short primer (5–10 lines in Korean, from the researcher's 핵심 개념) — the user must understand the concepts to answer the questions. Questions the findings already answer: decide yourself and mark 자체 해소 with the evidence.

5. **Document.** Follow `templates/unknowns.md` in this skill's folder. Korean. Save to `docs/blindspot/YYYY-MM-DD-<slug>-unknowns.md`. Omit lenses that did not run from the 스캔 렌즈 line and drop their `### <lens>` sections (greenfield drops `similar-features`; code-only tasks drop `domain`).

6. **Verify.** Use `define_subagent` (from `.agents/plugins/dev-env-blindspot/agents/doc-verifier.md`) and spawn `doc-verifier` via `invoke_subagent` on the file; fix every issue, re-save.

7. **Hand off.** Tell the user (Korean): 설계 문서가 필요하면 `explainer`, 바로 구현이면 `work-report` 노트 모드로.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- Scanners return findings; YOU convert them to questions. A finding without a decision attached is noise.
- Do not serialize the scanner spawns — parallel or it takes 4x longer.
- Domain unknowns don't live in the repo — codebase lenses on a pure-domain task return empty findings. Classify territory first; route domain topics to `domain-researcher`.
