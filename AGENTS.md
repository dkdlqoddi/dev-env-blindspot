# AGENTS.md

This file provides guidance to Antigravity when working with code in this repository.

## What this repo is

Shared Antigravity Plugin that provides skills and agents for the "Finding Your Unknowns" lifecycle. Other projects consume this as a git submodule mounted at `.agents/plugins/dev-env-blindspot`. 
It implements Thariq's "Finding Your Unknowns" lifecycle: `requirements-interview` → `blindspot-pass` → `explainer` → `work-report`, orchestrated by `blindspot-flow`.

## Test

```bash
bash test/check.sh
```

Covers: mandate output names all 5 skills, YAML frontmatter lint (`name`, `description`) across exactly 9 files (5 skills + 4 agents), and validates plugin.json structure.

## Conventions

- Model-facing instruction files (`SKILL.md`, `agents/*.md`, `MANDATE.md`): English. User-facing deliverables the skills generate: Korean. Do not mix.
- Skill frontmatter `description` is the trigger condition — always "Use when ...".
- Every SKILL.md has a `## Gotchas` section. Append recurring failure points there; never delete entries or create separate gotcha docs.
- Agents are read-only by design — keep `tools` minimal (`Bash` only where git inspection is required, with read-only instructions in the body).
- Deliverable path contract baked into skills: `docs/blindspot/YYYY-MM-DD-<slug>-{requirements,unknowns,explainer,report}.md`, `docs/blindspot/quiz/*.html`, `docs/blindspot/<slug>-implementation-notes.md` (no date prefix).

## Consumer contract (breaking-change checklist)

Renaming or moving any of these breaks consumer projects — update `test/check.sh` + `README.md` together:

- `skills/<name>/` directory names (= installed skill names, referenced in `MANDATE.md`)
- `agents/*.md` filenames (= subagents invoked inside SKILL.md files)
- `MANDATE.md` path (referenced by consumer AGENTS.md)

## Design docs

Spec: `docs/superpowers/specs/2026-07-06-blindspot-agents-skills-design.md`. Plan: `docs/superpowers/plans/2026-07-06-blindspot-agents-skills.md`.
