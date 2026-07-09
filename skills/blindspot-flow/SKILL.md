---
name: blindspot-flow
description: Use when the user invokes /blindspot-flow or asks to run a feature through the full lifecycle end-to-end — thin orchestrator that sequences requirements-interview, blindspot-pass, explainer, then work-report notes mode through implementation and report mode at the end.
---

# Blindspot Flow

Thin orchestrator. All real logic lives in the four lifecycle skills — this skill only sequences them.

## Workflow

Run the stages below in order. **Crucially, you must execute this flow under the strict procedural discipline of the `fablize` plugin.**

Before starting:
1. Read `.agents/plugins/dev-env-blindspot/external/fablize/skills/fablize/SKILL.md` and fully adopt its rules.
2. In all your terminal commands for `fablize`, treat `${CLAUDE_PLUGIN_ROOT}` as exactly `.agents/plugins/dev-env-blindspot/external/fablize`. Run the `fablize` setup if needed.
3. Use `goals.py create` to register the following 3 stages as concrete, verifiable goals.
4. Progress through each stage using `goals.py next`. Between stages, use `goals.py checkpoint` to record the generated markdown document (e.g., `docs/blindspot/...`) as concrete evidence before moving to the next goal.

The 3 stages to register and execute are:
1. `requirements-interview` → requirements doc
2. `blindspot-pass` → unknowns doc
3. `explainer` → design doc

For each stage, invoke it by reading its `SKILL.md` file and following its instructions. Before each stage, check `docs/blindspot/` for an existing deliverable for this topic; if found, tell the user (Korean) and offer reuse or redo.

**After Stage 3 Completes:**
Stop execution and output the following exact message to the user:
> 기획과 설계 문서 작성이 완료되었습니다! 이제 자리에서 일어나셔도 됩니다. 남은 구현과 자체 검증을 자율적으로 끝마치게 하려면 채팅창에 **`/goal blindspot-goal`** 이라고 입력해 주세요.

Do not inline a stage's logic here; if a stage needs fixing, fix that skill.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- Skipping a stage is the user's call, not yours — always surface the option, never silently skip.
