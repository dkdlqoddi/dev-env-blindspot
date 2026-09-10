# ANTIGRAVITY.md

This file provides guidance to Google Antigravity (AGY / Antigravity CLI / Antigravity IDE) when working with code in this repository.

## What this repo is

Shared Antigravity skills, agents, and rules that other projects consume as a git submodule mounted at `.agents/shared/`, wired up by `install.sh` (individual relative symlinks into `.agents/skills`, `.agents/agents`, `.agents/rules`, and an `@.agents/shared/MANDATE.md` import in the consumer's `AGENTS.md` / `ANTIGRAVITY.md`). It implements Thariq's "Finding Your Unknowns" lifecycle: `requirements-interview` → `blindspot-pass` → `explainer` → `work-report`, orchestrated by `blindspot-flow`. In addition, implementation can run via an Antigravity swarm: `swarm-plan` → `swarm-run` → `swarm-review`. Deliverables are a fixed set of living documents per area — three tiers, `rules.md` / `map.md` / `specs/<unit>.md` — updated in place, never dated per-cycle files.

This branch (`antigravity-pure`) runs the entire lifecycle — from requirements interview and blindspot detection, through specification and planning, to swarm or in-session execution, auditing, and pre-merge quiz generation — **exclusively inside Google Antigravity**.

## Test

```bash
bash test/check.sh
```

Covers:
- Mandate hook output names all 8 skills and the tier + working paths (incl. `docs/swarm/`).
- YAML frontmatter lint (`name`, `description`) across all 8 skills (`skills/*/SKILL.md`).
- Frontmatter contract of all 8 Antigravity subagents (`agents/*.md` with `subagent: true`, `mainAgent: false`, `model: flash`, `commandExecutionPolicy: auto`, and an explicit `tools:` allowlist drawn from the 9 allowed tools).
- Frontmatter contract of Antigravity rules (`rules/*.md` with `trigger: always_on`).
- Skill↔agent `TypeName: <name>` reference integrity in both directions (every referenced agent exists, every agent is referenced in skills and named in `MANDATE.md` Hard Rule 2).
- Readability-standard marker (`25 어절`) present in exactly 4 `SKILL.md` files.
- `install.sh` and `install-antigravity.sh` idempotency against a fake consumer project in a temp dir (run twice, assert symlinks and `AGENTS.md` / `ANTIGRAVITY.md` unchanged and every link resolving).
- `docs_check.py` running clean on the shipped templates and failing loudly on a broken fixture.
- `swarm_check.py` passing a valid plan package and failing a broken one (ownership overlap, dependency on later wave, missing brief, missing path, placeholder).
- Retired per-cycle strings absent from skills, agents, rules, and `MANDATE.md`.
- Template heading and bullet contract (tiers, notes, swarm plan/task/status/result).
- Every `templates/<file>` named in a `SKILL.md` ships in `skills/*/templates/`.
- `MANDATE.md` ≤ 60 lines.

## Conventions

- Model-facing instruction files (`SKILL.md`, `agents/*.md`, `rules/*.md`, `MANDATE.md`, `ANTIGRAVITY.md` frontmatter and bodies): English. User-facing deliverables the skills generate: Korean. Do not mix.
- Templates (`skills/*/templates/*`): deliverable text and placeholders Korean; instruction comments addressed to the generating model (`<!-- -->`, `//`) English. Cross-referenced identifiers (lens names, tier section headings, quadrant terms, 웨이브) keep their established form. Skills locate sections by exact heading text, so template headings are a contract (checked by `test/check.sh`).
- Template ownership: `rules.md` / `map.md` belong to blindspot-pass, `spec.md` to explainer, `notes.md` / `quiz.html` to work-report, `plan.md` / `task.md` to swarm-plan, `status.md` / `result.md` to swarm-run. A skill that needs another skill's template names it by skill ("the `explainer` skill's `templates/spec.md`", installed at `.agents/skills/explainer/templates/spec.md`); templates are never duplicated.
- Skill frontmatter `description` is the trigger condition — always "Use when ...". Antigravity skills follow the same rule; their `name` is the slash command.
- Every `SKILL.md` has a `## Gotchas` section. Append recurring failure points there; never delete entries. When a structural change makes an entry factually wrong, rewrite it to name the new referent — correcting a stale referent is not deletion.
- Antigravity subagents (`agents/*.md`) use Antigravity's frontmatter: `subagent: true`, `mainAgent: false`, `model: flash`, `commandExecutionPolicy: auto`, and an explicit `tools:` block sequence drawn from the 9-name allowlist: `view_file`, `find_by_name`, `grep_search`, `list_dir`, `run_command`, `write_to_file`, `replace_file_content`, `read_url_content`, `search_web`. `commandExecutionPolicy: auto` ensures headless runs never wait on interactive prompts.
- Subagent responsibilities:
  - Exploration and research: `codebase-scanner` (repo lenses), `domain-researcher` (web research).
  - Verification and audit: `doc-verifier` (tier document quality), `change-analyzer` (diff analysis), `check-runner` (standard test/lint runner), `swarm-auditor` (swarm diff and claim audit).
  - Swarm execution: `swarm-worker` (implements single brief within owned files), `swarm-checker` (verifies wave with plan command).
- Deliverable path contract baked into skills and MANDATE: `docs/<area>/rules.md` (Tier 1, ≤60 lines), `docs/<area>/map.md` (Tier 2, ≤150 lines), `docs/<area>/specs/<unit>.md` (Tier 3, ≤200 lines), `docs/notes/<slug>.md` (deleted at acceptance), `docs/quiz.html` (overwritten each cycle), `docs/swarm/` (plan package `plan.md` + `tasks/<id>.md` written by swarm-plan, run records `status.md` + `results/<id>.md` written by swarm-run / swarm-worker; deleted at acceptance). An area is a directory under `docs/` holding `map.md`; canonical areas are `frontend` and `backend`, a single-area project uses `core`.
- Swarm plan contract (enforced by `skills/swarm-plan/scripts/swarm_check.py`, called by swarm-plan and by swarm-run before dispatch): task ids `T01`…, one brief per id, 웨이브 numbers, 선행 ids in earlier 웨이브 only, 소유 파일 as backticked paths disjoint within a 웨이브, briefs with 목표 / 해야 할 일 / 완료 조건 / 검증, no placeholders. Workers share the tree (`Workspace: inherit`) — ownership disjointness is the only thing keeping parallel writes safe.
- Readers are separated per section, not per document. Non-developer register (plain Korean first with the term in parentheses; no arrows/code syntax; one fact per sentence, ≤25 어절; quiz options ≤40 chars; quiz answerable from its own 변경 요약): spec 목적과 배경 / 요구사항 / 동작 방식 / 의도적 범위 제외, the 결정 and 질문 cells, map 영역 개요 and 하는 일, rules 규칙 cells, interview and blindspot questions, the whole quiz. Technical register: 근거, 위치, 처리, 기각한 대안, 변경 이력, 리뷰 포인트, and the whole swarm package. The standard is intentionally duplicated across 4 skills for self-containment (`requirements-interview`, `blindspot-pass`, `explainer`, `work-report`) — edit it in all of them together; swarm skills must not carry the marker. Enforced by `skills/work-report/scripts/docs_check.py`.
- Section ownership in a spec: explainer rewrites 목적과 배경 / 동작 방식 / 의도적 범위 제외 (keeping work-report's as-built additions); requirements-interview appends 요구사항 (blindspot-pass may add domain acceptance criteria there); 결정 기록 / 엣지케이스와 제약 are append-only for everyone; a 열린 질문 row is removed by the skill that records its answer; whichever skill first writes to a unit creates its spec with every heading and flips the map's 상세 명세 cell; work-report writes 변경 이력 after the quiz passes. Empty sections are not placeholders. Swarm skills never write tier documents; swarm-review writes only `docs/notes/<slug>.md`.
- Question policy lives once in `MANDATE.md` and `rules/mandate.md`; `blindspot-pass` and `work-report` implement the mechanics. Bootstrap decides areas from evidence and asks only when evidence conflicts. Swarm workers never ask: briefs pre-decide everything, and blockers are recorded under 막힌 것.

## Consumer contract (breaking-change checklist)

Renaming or moving any of these breaks consumer projects — update `install.sh` / `install-antigravity.sh` + `test/check.sh` + `README.md` together:

- `skills/<name>/` directory names (= installed skill names, referenced in `MANDATE.md` and `rules/mandate.md`)
- `agents/*.md` filenames (= `TypeName: <name>` values referenced inside SKILL.md files)
- `rules/*.md` filenames (= rules installed under `.agents/rules/`)
- `hooks/mandate.sh`, `MANDATE.md`, `install.sh`, `install-antigravity.sh` paths
- Tier paths `docs/<area>/{rules.md,map.md,specs/}`, `docs/notes/`, `docs/quiz.html`, `docs/swarm/{plan.md,tasks/,status.md,results/}`
- `skills/explainer/templates/spec.md`, `skills/work-report/scripts/docs_check.py`, `skills/swarm-plan/scripts/swarm_check.py`, `skills/swarm-run/templates/result.md`

## Design docs

Founding spec/plan: `docs/superpowers/specs/2026-07-06-blindspot-agents-skills-design.md`, `docs/superpowers/plans/2026-07-06-blindspot-agents-skills.md`. Three-tier documentation structure: `docs/superpowers/specs/2026-09-07-three-tier-docs-design.md`, `docs/superpowers/plans/2026-09-07-three-tier-docs.md`. Claude Code / Antigravity swarm split: `docs/superpowers/specs/2026-09-08-antigravity-swarm-design.md`. Pure Antigravity unification: `docs/superpowers/specs/2026-09-10-antigravity-pure-design.md`.
