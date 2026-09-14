---
name: swarm-run
description: Use when the user asks to run, continue, or resume the swarm (/swarm-run, "스웜 실행", "계획대로 병렬 실행", "이어서 실행") and docs/swarm/plan.md exists. Executes the plan written by Claude Code's swarm-plan skill by looping on scripts/swarm_next.py — the script decides every dispatch, retry, recovery, and commit and writes docs/swarm/status.md; this skill relays each printed action to swarm-worker and swarm-checker subagents, a whole 웨이브 per call. Never plans and never edits tier documents.
---

# Swarm Run

You are the dispatcher's hands, not its judgment. `scripts/swarm_next.py` in this skill's folder reads the plan, the status file, and the result files, and prints exactly one action at a time. Carry each action out literally and hand the outcome back to the script. Which tasks run, which retry, what gets committed, and when the run stops are the script's decisions, never yours.

## Loop

1. Run `python3 .agents/skills/swarm-run/scripts/swarm_next.py next`.
2. Read the first line of the output and act on it:
   - `ACTION: dispatch` — make ONE `invoke_subagent` call whose `Subagents` argument is the printed JSON array, copied verbatim. The call returns before the subagents finish and their replies arrive as messages: wait until every entry has replied. Then run the printed `collect` command.
   - `ACTION: verify` — make ONE `invoke_subagent` call with the printed single-entry array (swarm-checker). When it replies, run the printed `verified` command with the checker's whole reply pasted between the two `SWARM_CHECK_REPLY` lines.
   - `ACTION: wait` — follow the printed options exactly: if a named subagent has not replied yet, wait for it and run `collect` again; if every one has replied already, run `collect --final`.
   - `ACTION: finish` or `ACTION: stop` — reply to the user with the text below the `---` line, verbatim, and end.
3. Feed the output of every command back into step 2. There is no other way out of the loop.

If `invoke_subagent` answers that `swarm-worker` or `swarm-checker` is not found, define it once with `define_subagent` (name = the TypeName, enable_write_tools true, system_prompt = the body of `.agents/agents/<TypeName>.md`) and repeat the same call. The checker needs enable_write_tools only because `run_command` ships in that group; its system prompt forbids edits.

## Rules

- Never edit anything under `docs/swarm/` — the script owns status.md, Claude Code owns plan.md and tasks/, workers own results/ — or under `docs/<area>/`. Never create a task.
- Never do a task yourself, never run a verification command yourself, never run git yourself — the script commits.
- Never change, shorten, reorder, or summarise the printed JSON, prompts, or commands.
- Run `next` only to start or resume a run, never while subagents are still working: `next` treats unfinished work as interrupted and resets it.
- Never ask the user mid-run.
- Keep your context small: the script's output and the subagents' one-line replies. Never open briefs, results, source files, or logs.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries — correct a stale entry's referent instead. -->
- Dispatching one task per call serialises the swarm — every dispatch action is ONE `invoke_subagent` call with all the printed entries.
- A worker's reply is not the record; `docs/swarm/results/<id>.md` is. The script counts a result only when the file exists with the current 시도, whatever the reply said.
- Running the verification command yourself floods your context with logs — the checker returns failures only.
- Workspace `branch` gives each worker a private copy nobody merges — always `inherit`; disjoint 소유 파일 is what keeps the shared tree safe.
- `swarm_next.py` commits each 웨이브 with `git add -A`, which commits whatever `.gitignore` lets through — in the first smoke test a `__pycache__` landed in a 웨이브 commit because the scratch project had none. The auditor flags such files as 주인 없음; the fix is the consumer's `.gitignore`, not a narrower add.
- Since agy 1.1.28 an expired `--print-timeout` ends the run with exit code 0 and partial output, so an interrupted swarm looks finished. Rerunning `/swarm-run` is always safe: `next` keeps finished results and resets unfinished tasks.
- `invoke_subagent` returns before its subagents finish (measured on agy 1.2.2); running `collect` straight after the call only reports missing results — wait for the replies first.
- A checker reply pasted inside double quotes gets its backticked paths executed by the shell — always pass it through the quoted heredoc the script prints.
