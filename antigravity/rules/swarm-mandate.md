---
trigger: always_on
---

# Swarm mandate

This project plans in Claude Code and executes in Antigravity.

- The plan is `docs/swarm/plan.md` with one brief per task under `docs/swarm/tasks/`. Only Claude Code's `swarm-plan` skill writes it. Never write, extend, or repair a plan here.
- When that plan exists and the user asks to run, continue, or resume the swarm, activate the `swarm-run` skill. Do not implement plan tasks in this conversation yourself.
- Never edit the tier documents under `docs/<area>/` (`rules.md`, `map.md`, `specs/`); Claude Code's lifecycle skills own them. Swarm records go to `docs/swarm/status.md` and `docs/swarm/results/` only.
- Messages and result files for the user are Korean; prompts to subagents are English.
