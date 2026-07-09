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
1. Read `.agents/plugins/dev-env-blindspot/external/fablize/skills/fablize/SKILL.md` and fully adopt its rules. If `fablize` is not set up (i.e. `~/.fablize/progress.json` is missing), automatically run `bash ${CLAUDE_PLUGIN_ROOT}/setup/setup.sh local` to bypass interactive onboarding.
2. In all your terminal commands for `fablize`, treat `${CLAUDE_PLUGIN_ROOT}` as exactly `.agents/plugins/dev-env-blindspot/external/fablize`. (On Windows environments, prefix python commands with `PYTHONUTF8=1` or `$env:PYTHONUTF8=1` to avoid unicode encode errors).
3. Use `goals.py create` to register your implementation plan steps as concrete, verifiable goals. Use this format:
   `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/goals.py create --brief "Autonomous Implementation" --goal "Context Gathering::scan codebase and finalize plan" --goal "Implementation::code the feature" --goal "Final Report::verify and document"`

The autonomous stages to execute are:

### Stage 1: Context Gathering (Intent Resolution)
1. Read `docs/blindspot/` for existing `requirements`, `unknowns`, and `explainer` docs. 
2. **Autonomous Intent Resolution**: If any document is missing, or if the user's `/goal` prompt introduces new ambiguities, you MUST NOT ask the user. Instead, ask the codebase. Spawn `codebase-scanner` agents in parallel for `conventions`, `similar features`, `integration points`, and `edge cases`.
3. Put extreme effort into understanding the user's intent by finding precedence in the code. Synthesize your findings into a definitive `explainer` doc (if missing) or append to the implementation notes.
4. Check off the first goal using `goals.py checkpoint`.

### Stage 2: Implementation
1. Begin implementation based on the `explainer` doc and your context gathering.
2. Keep notes: Automatically maintain `docs/blindspot/<slug>-implementation-notes.md`. Append one Korean entry per event at decision time (결정 / 이유 / 검토한 대안 / 보수적 선택 여부 / 계획과의 이탈 여부).
3. Progress through your fablize goals using `goals.py next`. 
4. Between goals, use `goals.py checkpoint` to record progress. 

### Stage 3: Final Verification and Report
1. **Important**: Fable enforces a verification gate on the final goal. When checkpointing the final goal, you MUST use `--verify-cmd` and provide passing automated test output (e.g. `npm test`, `check.sh`, `pytest`) as `--verify-evidence` before checking it off.
2. When implementation and verification are complete, run the logic of the `work-report` skill (report mode).
3. Spawn `change-analyzer` and merge its output with the implementation notes and explainer.
4. Write the final report following `templates/report.md` (Korean) to `docs/blindspot/YYYY-MM-DD-<slug>-report.md`.
5. **EXCEPTION**: Follow `work-report` report mode logic, but do NOT generate the `Pre-Merge Quiz`. Because this is an autonomous task, system verification via `fablize` tests replaces the human quiz.
6. Once the report is generated, you may conclude the task.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- **Never stop to ask the user clarifying questions.** You are in `/goal` mode. "Putting effort into understanding intent" means aggressively scanning the codebase (`codebase-scanner`) or domain (`domain-researcher`) to answer your own questions.
- If something remains ambiguous after exhaustive scanning, make the most conservative, reasonable assumption, log it explicitly in the implementation notes (with your rationale), and proceed.
- You cannot finish this task without verifiable evidence. Run the code, run the tests, and use the terminal output as evidence for your goals.
