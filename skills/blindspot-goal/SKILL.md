---
name: blindspot-goal
description: Use when the user invokes /goal with blindspot-goal, or wants autonomous implementation of a planned feature. It executes the implementation and report phases of the blindspot lifecycle under strict autonomous procedural discipline.
---

# Blindspot Goal

Autonomous orchestrator. This skill takes over after `blindspot-flow` has finished the interactive planning stages. It drives the implementation and reporting completely autonomously.

## Workflow

You are now in autonomous mode (likely running under `/goal`). Do not stop to ask the user for permission. Make executive decisions, document them, and push forward until the implementation is verifiable and complete.

**Crucially, you must execute this flow under the strict procedural discipline of the `fablize` plugin.**

Before starting:
1. Read `.agents/plugins/dev-env-blindspot/external/fablize/skills/fablize/SKILL.md` and fully adopt its rules.
2. In all your terminal commands for `fablize`, treat `${CLAUDE_PLUGIN_ROOT}` as exactly `.agents/plugins/dev-env-blindspot/external/fablize`. 
3. Use `goals.py create` to register your implementation plan steps as concrete, verifiable goals.
4. Read the `requirements`, `unknowns`, and `explainer` docs from `docs/blindspot/` generated during the interactive phase.

The autonomous stages to execute are:

### Stage 1: Implementation
1. Begin implementation based on the `explainer` doc.
2. Keep notes: Automatically maintain `docs/blindspot/<slug>-implementation-notes.md`. Append one Korean entry per event at decision time (결정 / 이유 / 검토한 대안 / 보수적 선택 여부 / 계획과의 이탈 여부).
3. Progress through your fablize goals using `goals.py next`. 
4. Between goals, use `goals.py checkpoint` to record progress. **You must use `verify-cmd` and provide passing test output as evidence before checking off implementation goals.**

### Stage 2: Final Report
1. When implementation and verification are complete, run `work-report` report mode logic.
2. Spawn `change-analyzer` and merge its output with the implementation notes and explainer.
3. Write the final report following `templates/report.md` (Korean) to `docs/blindspot/YYYY-MM-DD-<slug>-report.md`.
4. **EXCEPTION**: Do NOT generate the `Pre-Merge Quiz`. Because this is an autonomous task, system verification via `fablize` replaces the human quiz.
5. Once the report is generated, you may conclude the task.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- Do not stop to ask the user clarifying questions. You are in goal mode. If something is ambiguous, make the most conservative, reasonable assumption, log it in the implementation notes, and proceed.
- You cannot finish this task without verifiable evidence. Run the code, run the tests, and use the terminal output as evidence for your goals.
