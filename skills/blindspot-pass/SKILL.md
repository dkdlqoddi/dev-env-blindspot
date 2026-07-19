---
name: blindspot-pass
description: Use when starting work in an unfamiliar codebase or domain, before writing an implementation plan, or when the user asks what they might be missing ("내가 모르는 게 뭐지") — fans out parallel codebase-scanner agents across four lenses (plus a domain-researcher for knowledge outside the codebase), converts unknown unknowns into concrete decidable questions, resolves them with the user, and writes a Korean unknowns document.
---

# Blindspot Pass

Unknown unknowns are the failures you don't see coming. Concretize them into decidable questions before they become rework.

## Workflow

1. **Collect input and classify territory.** The task description, plus `docs/blindspot/*-requirements.md` for this topic if it exists — read it; do not re-ask what it already answers. Split the unfamiliarity into two territories: code (this repository) and domain (knowledge living outside the codebase — e.g. color grading, payment standards). A task can have both.

2. **Fan out scanners.** Spawn `codebase-scanner` agents IN PARALLEL (one message, multiple Agent calls, subagent_type: `codebase-scanner`), one per lens:
   - `conventions`
   - `similar-features`
   - `integration-points`
   - `edge-cases`
   Each agent receives: its lens, the task description, and the requirements doc path if present. Use 3 lenses (drop `similar-features`) when the project is greenfield; skip the codebase lenses entirely only when the task touches no code.

   If domain territory exists, add ONE `domain-researcher` agent (subagent_type: `domain-researcher`) to the same parallel batch, with: the domain topic, the task description, and what the user already knows.

3. **Synthesize.** Merge findings yourself (plain reasoning, no extra agent). For each finding: restate it as a concrete, decidable question ("X를 어떻게 할지", not "X 주의") written for someone who has never seen the code — unavoidable technical terms plain Korean first with the term in parentheses, code identifiers only after a plain description, one fact per sentence, ≤25 어절 each. Assign a quadrant, sort by architecture impact. Keep evidence attached — `file:line` for code findings, source URL for domain findings; evidence stays technical.

4. **Resolve with the user.** Present questions in Korean via AskUserQuestion, architecture-changing first. Questions, options, and the primer follow the same non-developer bar as step 3. If domain findings exist, open with a short primer (5–10 lines in Korean, from the researcher's 핵심 개념, short sentences with an everyday comparison for each abstract concept) — the user must understand the concepts to answer the questions. Questions the findings already answer: decide yourself and mark 자체 해소 with the evidence. If more than 7 questions remain after self-resolution, do not present them all — the count signals thin evidence, so spawn follow-up `codebase-scanner` / `domain-researcher` agents targeted at the weakest-evidence clusters and self-resolve again. Present at most the 7 highest architecture-impact questions; move the rest to 미해소 항목 with a 재방문 시점.

5. **Document.** Follow `templates/unknowns.md` in this skill's folder. Korean. The question, decision, and hold-reason cells across both tables (구체화된 질문·질문·결정·보류 이유) are read by non-developers — apply the step 3 sentence bar to them; before saving, self-check every sentence in those cells: could someone who has never seen code follow it, and is it one fact within 25 어절? The 발견(근거) column and the 스캔 원본 요약 sections are technical evidence for later stages — technical language is correct there; do not simplify it. Save to `docs/blindspot/YYYY-MM-DD-<slug>-unknowns.md`. Omit lenses that did not run from the 스캔 렌즈 line and drop their `### <lens>` sections (greenfield drops `similar-features`; code-only tasks drop `domain`).

6. **Verify.** Spawn `doc-verifier` on the file; fix every issue, re-save.

7. **Hand off.** Tell the user (Korean): 설계 문서가 필요하면 `explainer`, 바로 구현이면 `work-report` 노트 모드로.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- Scanners return findings; YOU convert them to questions. A finding without a decision attached is noise.
- Do not serialize the scanner spawns — parallel or it takes 4x longer.
- Domain unknowns don't live in the repo — codebase lenses on a pure-domain task return empty findings. Classify territory first; route domain topics to `domain-researcher`.
- A concretized question the user cannot parse defeats the whole pass — the decision gets guessed, not made. Questions and decisions in plain Korean; evidence and scan summaries stay technical.
- Clean vocabulary does not equal readable: a 40+ 어절 sentence with nested clauses locks out the same readers even with zero jargon — the one-fact / ≤25 어절 bar is part of the standard.
- A long question list is an analysis failure, not thoroughness: past ~7, answer quality collapses and guessed answers become fake requirements. The cap triggers more scanning, never more asking.
