---
name: swarm-plan
description: Use when implementation is to be handed to an Antigravity swarm — the user asks to split the work for parallel agents ("스웜으로", "병렬로 나눠서", "swarm-plan"), blindspot-flow stage 4 takes the swarm route, or swarm-review sends failed tasks back for a delta round — turns the confirmed unit spec into a plan package under docs/swarm/ (plan.md plus one self-contained brief per task, ordered in 웨이브 with disjoint file ownership and a runnable check each) that a fast, context-free model can execute without judgment; validated by scripts/swarm_check.py.
---

# Swarm Plan

The strong model thinks once, in full context; the fast models execute many times, in parallel, with no context but the brief. Everything a worker would have to decide is decided here and written down.

## Workflow

0. **Preconditions.** Locate the touched unit's `docs/<area>/specs/<unit>.md` through the 단위 table of `docs/<area>/map.md`. It must have 요구사항 and 동작 방식 — if not, tell the user (Korean) and recommend `requirements-interview` / `explainer` first; never plan from a prompt alone. Read `docs/<area>/rules.md` (표준 명령 → 전체 검증; 관례 → what every brief must respect), the 단위 table (위치 → file ownership), and the touched specs. Record `git rev-parse --short HEAD` as the 기준 커밋; if `git status --porcelain` shows uncommitted code changes, ask the user to commit them first — the swarm's 웨이브 commits must contain only swarm work.

1. **Evidence.** Spawn IN PARALLEL (one message, two Agent calls) `codebase-scanner` (subagent_type: `codebase-scanner`) with lens `integration-points` (everything the change must touch — this is the file inventory the ownership sets are cut from) and lens `similar-features` (prior art the workers will imitate — a fast model does well with a concrete `path:line` to copy and badly with a description). Both receive the task description, the tier paths, and the 위치 globs of the touched units. Skip only when the project has no code.

2. **Decompose.** Cut the work into tasks that satisfy all of:
   - **Self-contained** — finishable by a fast model that reads only the brief and the files it names; S–M size (roughly one file group, one behavior). Bigger → split.
   - **Disjoint** — within one 웨이브, no two tasks own the same path. A shared file means one merged task or a later 웨이브.
   - **Checkable** — every task names a 검증 the worker can run (one test file, a lint, a script). No such check exists → put a test-writing task in an earlier 웨이브, or state in the 목표 which 전체 검증 files cover it.
   - **Interface-fixed** — every name two tasks both touch (function signature, file name, schema, route) is written verbatim in each of their briefs; workers cannot talk to each other.
   - **Diverse** — vary the 역할: 구현, 테스트 작성, 문서 갱신, 마이그레이션, 정리, 설정. Typical 웨이브 order: contracts / scaffolds / tests → implementations → wiring, docs, cleanup.
   - **Bounded** — at most 동시 실행 상한 (default 8) tasks per 웨이브 and about 20 per round; more work → another round after `swarm-review`.
   What the swarm must not do (design decisions still open, destructive migrations, anything needing the user) stays out and is named in the plan's 목표.

3. **Write the package.** `docs/swarm/plan.md` from `templates/plan.md` in this skill's folder; one `docs/swarm/tasks/<id>.md` per task from `templates/task.md`. Every brief: literal paths, the 참고 파일 to imitate, 완료 조건 phrased as checks ("X를 호출하면 Y를 돌려준다"), the 검증 command. Ban the words 필요하면 and 적절히 — they hand the decision to the weakest model in the chain (`swarm_check.py` rejects them). Add the 회차 row (회차 1, 범위 전체).

4. **Validate.** Run `python3 .claude/skills/swarm-plan/scripts/swarm_check.py docs/swarm/plan.md` (`scripts/swarm_check.py` in this skill's folder) and fix every violation. Then spawn `doc-verifier` (subagent_type: `doc-verifier`) on `docs/swarm/plan.md` and on the two largest briefs, naming all sections as filled; fix every placeholder, contradiction, and ambiguity it reports.

5. **Open the notes.** Ensure `docs/notes/<slug>.md` exists (the `work-report` skill's `templates/notes.md`, installed at `.claude/skills/work-report/templates/notes.md`) and append one entry: the decomposition decision (웨이브 count, what was kept out of the swarm and why) — `work-report` report mode promotes it later.

6. **Hand off.** Commit the package (`git add docs/swarm docs/notes && git commit -m "swarm: 계획 <slug>"`), then tell the user (Korean): Antigravity에서 `/swarm-run` 실행 — 앱이면 이 프로젝트를 열고 채팅에 `/swarm-run`; CLI면 프로젝트 루트에서
   `agy --add-dir "$PWD" -p '/swarm-run' --model gemini-3.8-flash-medium --dangerously-skip-permissions --print-timeout 60m`
   끝나면 Claude Code에서 `swarm-review`.

**Re-plan round** (called from `swarm-review` with the failed, held, or deviated task ids): keep every 완료 확인 task untouched; rewrite only the named briefs — fold each 막힌 것 text in, split a task that was too big, add a 선행 where an interface was missing; append a 회차 row naming the ids; re-run step 4; tell the user to run `/swarm-run` again (it resumes from `docs/swarm/status.md` and re-dispatches only tasks that are not 완료).

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries — correct a stale entry's referent instead. -->
- "필요하면 …" in a brief is a decision delegated to the model least able to make it; decide it here or keep the task out of the swarm.
- Two tasks touching one file in the same 웨이브 overwrite each other on the shared tree — `swarm_check.py` is the guard, not the reviewer's eye.
- A task without a runnable check reports 완료 by hope; the swarm's only feedback loop is the command the worker can run.
- Interfaces described once, in one brief, are invented twice — spell them out verbatim in every brief that touches them.
- A plan written from the prompt instead of the spec reproduces the prompt's blind spots at 8x parallelism.
