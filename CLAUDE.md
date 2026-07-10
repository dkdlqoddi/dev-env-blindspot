# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Shared Claude Code skills/agents that other projects consume as a git submodule mounted at `.claude/shared/`, wired up by `install.sh` (individual relative symlinks into `.claude/skills` and `.claude/agents`, a SessionStart hook running `hooks/mandate.sh`, and a `@.claude/shared/MANDATE.md` import in the consumer's CLAUDE.md). It implements Thariq's "Finding Your Unknowns" lifecycle: `requirements-interview` → `blindspot-pass` → `explainer` → `work-report`, orchestrated by `blindspot-flow`.

## Test

```bash
bash test/check.sh
```

Covers: mandate hook output names all 5 skills, YAML frontmatter lint (`name`, `description`) across exactly 9 files (5 skills + 4 agents), and `install.sh` idempotency against a fake consumer project in a temp dir (run twice, assert symlinks/settings/CLAUDE.md unchanged).

Quiz HTML browser verification: Playwright MCP blocks `file://` — serve via `python3 -m http.server` and use localhost.

## Conventions

- Model-facing instruction files (`SKILL.md`, `agents/*.md`, `MANDATE.md`): English. User-facing deliverables the skills generate: Korean. Do not mix.
- Skill frontmatter `description` is the trigger condition — always "Use when ...".
- Every SKILL.md has a `## Gotchas` section. Append recurring failure points there; never delete entries or create separate gotcha docs.
- Agents are read-only by design — keep `tools` minimal (`Bash` only where git inspection is required, with read-only instructions in the body).
- Deliverable path contract baked into skills: `docs/blindspot/YYYY-MM-DD-<slug>-{requirements,unknowns,explainer,report}.md`, `docs/blindspot/quiz/*.html`, `docs/blindspot/<slug>-implementation-notes.md` (no date prefix).
- Non-developer readability rules are intentionally duplicated across 5 skills for self-containment (work-report steps 3–4, explainer step 2, requirements-interview steps 3–4, blindspot-pass steps 3–5) — edit the standard in all of them together.

## Consumer contract (breaking-change checklist)

Renaming or moving any of these breaks consumer projects — update `install.sh` + `test/check.sh` + `README.md` together:

- `skills/<name>/` directory names (= installed skill names, referenced in `MANDATE.md`)
- `agents/*.md` filenames (= `subagent_type` values referenced inside SKILL.md files)
- `hooks/mandate.sh`, `MANDATE.md` paths (referenced by consumer `settings.json` and CLAUDE.md import line)

## Design docs

Founding spec/plan: `docs/superpowers/specs/2026-07-06-blindspot-agents-skills-design.md`, `docs/superpowers/plans/2026-07-06-blindspot-agents-skills.md`. Later feature cycles accumulate dated spec/plan pairs in the same folders.
