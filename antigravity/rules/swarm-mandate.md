---
trigger: always_on
---

# Swarm mandate

This project plans in Claude Code and executes in Antigravity.

- The plan is `docs/swarm/plan.md` with one brief per task under `docs/swarm/tasks/`. Only Claude Code's `swarm-plan` skill writes it. Never write, extend, or repair a plan here.
- When that plan exists and the user asks to run, continue, or resume the swarm, activate the `swarm-run` skill. Do not implement plan tasks in this conversation yourself.
- The swarm runs only on Gemini 3.8 Flash (High): the CLI starts it with `--model gemini-3.8-flash-high --effort high`, the app with Gemini 3.8 Flash (High) selected. Every swarm agent file says `model: inherit`, so any other model — medium, low, flash-tiered, pro — would run the whole swarm on that model. Never start or suggest a swarm run on another model.
- Never edit the tier documents under `docs/<area>/` (`rules.md`, `map.md`, `specs/`); Claude Code's lifecycle skills own them. Swarm records are `docs/swarm/status.md`, written only by the swarm-run skill's `swarm_next.py`, and `docs/swarm/results/`, written by workers.
- Messages to the user are Korean. Prompts to subagents and the free text of result files are English, keeping the templates' Korean labels verbatim.
