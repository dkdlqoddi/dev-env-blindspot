# ANTIGRAVITY.md

This file provides guidance to Antigravity (antigravity.google) when working with code in this repository.

## What this repo is

Shared Antigravity skills/agents that other projects consume as a git submodule mounted at `.antigravity/shared/`, wired up by `install.sh` (individual relative symlinks into `.antigravity/skills` and `.antigravity/agents`, a SessionStart hook running `hooks/mandate.sh`, and a `@.antigravity/shared/MANDATE.md` import in the consumer's ANTIGRAVITY.md). It implements Thariq's "Finding Your Unknowns" lifecycle: `requirements-interview` → `blindspot-pass` → `explainer` → `work-report`, orchestrated by `blindspot-flow`. Deliverables are a fixed set of living documents per area — three tiers, `rules.md` / `map.md` / `specs/<unit>.md` — updated in place, never dated per-cycle files.

## Test

```bash
bash test/check.sh
```

Covers: mandate hook output names all 5 skills and the tier paths; YAML frontmatter lint (`name`, `description`) across exactly 10 files (5 skills + 5 agents); skill↔agent `TypeName` reference integrity in both directions (every referenced agent exists, every agent is referenced); readability-standard marker (`25 어절`) present in exactly 4 SKILL.md files; `install.sh` idempotency against a fake consumer project in a temp dir (run twice, assert symlinks/settings/ANTIGRAVITY.md unchanged); `docs_check.py` running clean on the shipped templates and failing loudly on a broken fixture (over-cap file, dangling map link, unlisted spec, over-long sentence); retired per-cycle strings (`docs/blindspot`, `YYYY-MM-DD-`, `quiz_check.py`, `implementation-notes`) absent from skills/agents/MANDATE; template heading contract; every `templates/<file>` a SKILL.md names ships in some skill; `MANDATE.md` ≤ 60 lines.

Quiz HTML browser verification: Playwright MCP blocks `file://` — serve via `python3 -m http.server` and use localhost.

## Conventions

- Model-facing instruction files (`SKILL.md`, `agents/*.md`, `MANDATE.md`): English. User-facing deliverables the skills generate: Korean. Do not mix.
- Templates (`skills/*/templates/*`): deliverable text and placeholders Korean; instruction comments addressed to the generating model (`<!-- -->`, `//`) English. Cross-referenced identifiers (lens names, tier section headings, quadrant terms) keep their established form. Skills locate sections by exact heading text, so template headings are a contract (checked by `test/check.sh`).
- Template ownership: `rules.md` / `map.md` belong to blindspot-pass, `spec.md` to explainer, `notes.md` / `quiz.html` to work-report. A skill that needs another skill's template names it by skill ("the `explainer` skill's `templates/spec.md`", installed at `.antigravity/skills/explainer/templates/spec.md`); templates are never duplicated.
- Skill frontmatter `description` is the trigger condition — always "Use when ...".
- Every SKILL.md has a `## Gotchas` section. Append recurring failure points there; never delete entries. When a structural change makes an entry factually wrong, rewrite it to name the new referent — correcting a stale referent is not deletion.
- Agents are read-only by design — they never edit files. Keep `tools` minimal (`run_command` only where git inspection or running the project's standard checks is required, with read-only instructions in the body). Pin cost-appropriate `model` in frontmatter: `flash` for mechanical checkers (doc-verifier, check-runner), `pro` for exploration/research (codebase-scanner, domain-researcher); change-analyzer inherits the session model because it feeds the merge gate.
- Deliverable path contract baked into skills and MANDATE: `docs/<area>/rules.md` (Tier 1, ≤60 lines), `docs/<area>/map.md` (Tier 2, ≤150), `docs/<area>/specs/<unit>.md` (Tier 3, ≤200), `docs/notes/<slug>.md` (deleted at acceptance), `docs/quiz.html` (overwritten each cycle). An area is a directory under `docs/` holding `map.md`; canonical areas are `frontend` and `backend`, a single-area project uses `core`.
- Readers are separated per section, not per document. Non-developer register (plain Korean first with the term in parentheses; no arrows/code syntax; one fact per sentence, ≤25 어절; quiz options ≤40 chars; quiz answerable from its own 변경 요약): spec 목적과 배경 / 요구사항 / 동작 방식 / 의도적 범위 제외, the 결정 and 질문 cells, map 영역 개요 and 하는 일, rules 규칙 cells, interview and blindspot questions, the whole quiz. Technical register: 근거, 위치, 처리, 기각한 대안, 변경 이력, 리뷰 포인트. The standard is intentionally duplicated across 4 skills for self-containment (requirements-interview steps 3–4, blindspot-pass steps 3–5, explainer step 2, work-report report step 4) — edit it in all of them together. The countable subset is enforced by `skills/work-report/scripts/docs_check.py` (quiz sentences/options, spec non-developer sections, tier line caps, map↔spec link integrity).
- Section ownership in a spec: explainer rewrites 목적과 배경 / 동작 방식 / 의도적 범위 제외 (keeping work-report's as-built additions); requirements-interview appends 요구사항 (blindspot-pass may add domain acceptance criteria there); 결정 기록 / 엣지케이스와 제약 are append-only for everyone (rows one line, date first, so `grep -h '^| 20' docs/<area>/specs/*.md` finds past decisions across the area); a 열린 질문 row is removed by the skill that records its answer; whichever skill first writes to a unit creates its spec with every heading and flips the map's 상세 명세 cell; work-report writes 변경 이력 after the quiz passes. Empty sections are not placeholders.
- Question policy (evidence-first asking, 7-question cap that triggers more scanning instead of more asking, no mid-work blocking on reversible decisions, per-cycle calibration) lives once in `MANDATE.md`; `blindspot-pass` step 4 and `work-report` notes/report modes implement the mechanics. Bootstrap (blindspot-pass step 0) decides areas from evidence and asks only when the evidence conflicts.

## Consumer contract (breaking-change checklist)

Renaming or moving any of these breaks consumer projects — update `install.sh` + `test/check.sh` + `README.md` together:

- `skills/<name>/` directory names (= installed skill names, referenced in `MANDATE.md`)
- `agents/*.md` filenames (= `TypeName` values referenced inside SKILL.md files)
- `hooks/mandate.sh`, `MANDATE.md` paths (referenced by consumer `settings.json` and ANTIGRAVITY.md import line)
- Tier paths `docs/<area>/{rules.md,map.md,specs/}`, `docs/notes/`, `docs/quiz.html` (referenced by MANDATE, every SKILL.md, README, `docs_check.py`)
- `skills/explainer/templates/spec.md` (created by four skills) and `skills/work-report/scripts/docs_check.py` (called from four SKILL.md files)

## Design docs

Founding spec/plan: `docs/superpowers/specs/2026-07-06-blindspot-agents-skills-design.md`, `docs/superpowers/plans/2026-07-06-blindspot-agents-skills.md`. Three-tier documentation structure: `docs/superpowers/specs/2026-09-07-three-tier-docs-design.md`, `docs/superpowers/plans/2026-09-07-three-tier-docs.md`. Later feature cycles accumulate dated spec/plan pairs in the same folders. This repo's own tier documents live in `docs/core/`; `docs/blindspot/` holds pre-tier history (two accepted reports and quizzes) and is not read by any skill.
