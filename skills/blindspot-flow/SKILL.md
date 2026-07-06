---
name: blindspot-flow
description: Use when the user invokes /blindspot-flow or asks to run a feature through the full lifecycle end-to-end — thin orchestrator that sequences requirements-interview, blindspot-pass, explainer, then work-report notes mode through implementation and report mode at the end.
---

# Blindspot Flow

Thin orchestrator. All real logic lives in the four lifecycle skills — this skill only sequences them.

## Workflow

Run the stages below in order, invoking each with the Skill tool by name. Before each stage, check `docs/blindspot/` for an existing deliverable for this topic; if found, tell the user (Korean) and offer reuse or redo. Between stages, confirm with the user before proceeding — they may stop or skip any stage.

1. `requirements-interview` → requirements doc
2. `blindspot-pass` → unknowns doc
3. `explainer` → design doc
4. `work-report` notes mode opens; implementation proceeds (implementation itself is outside this skill — only note-keeping is enforced)
5. When implementation is done: `work-report` report mode → report + pre-merge quiz

Do not inline a stage's logic here; if a stage needs fixing, fix that skill.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- Skipping a stage is the user's call, not yours — always surface the option, never silently skip.
