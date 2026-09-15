---
name: blindspot-pass
description: Use before writing an implementation plan for any non-trivial task (new feature, change with unclear requirements, unfamiliar code) or when the user asks what they might be missing ("내가 모르는 게 뭐지") — runs two parallel codebase_scanner agents, asks at most 3 decidable questions in one request_user_input call, and appends every decision to docs/decisions.md so no later session asks it again.
---

# Blindspot Pass

Unknown unknowns are the failures you don't see coming. Turn them into decidable questions before the plan exists, and record every answer where the next session will find it.

## Workflow

0. **Mode.** Run in plan mode when available. In any case this skill edits nothing except `docs/decisions.md`.

1. **Read the decisions.** Read `docs/decisions.md` at the project root. If it is missing, there are no rows yet — step 5 creates it. If it exceeds about 150 lines, grep it by the task's keywords instead of reading it all. Never ask what a row already answers — cite the row. A row whose 결정 starts with `보류:` is an open question, not an answer.

2. **Scan.** Spawn TWO `codebase_scanner` custom agents IN PARALLEL through the available collaboration tools: lens `integration-points` and lens `edge-cases`. Each receives the task description, relevant decision rows, verification commands from `AGENTS.md`, and the paths or globs the task touches, with the instruction to report only what the rows do not already settle or what contradicts them. Select the installed custom profile when the Codex surface supports it. If it cannot select that profile, read `.codex/agents/codebase_scanner.toml` and include its complete `developer_instructions` in each general subagent task. If subagent spawning remains unavailable, stop the pass and explain that it requires two parallel subagents; do not perform either scan in the parent context. These two scanners are the pass's whole exploration; do not launch other exploration agents over the same ground. Skip only when the project has no code.

3. **Convert.** Turn findings into decidable questions ("X를 어떻게 할지", not "X 주의"). Whatever the evidence settles, decide it yourself and record it as a row with 결정 주체 `자체`. Keep at most 3 questions, highest architecture impact first; park the rest as rows whose 결정 starts with `보류:` and whose 근거 names a 재방문 시점. Do not spawn more scanners to shrink the list.

4. **Ask.** Ask the remaining questions in ONE `request_user_input` call (at most 3 questions), in Korean, with 2–3 concrete options each, plain language first and technical terms in parentheses. If that tool is unavailable, ask the same batch directly in Korean. Skip this step when no question remains.

5. **Record.** Append one row per answered, self-decided, or parked question to `docs/decisions.md`: 날짜 | 영역 | 결정 | 근거 | 기각한 대안 | 결정 주체. One line per row, append-only; never edit or delete an existing row — to supersede one, add a new row whose 근거 names the old row's date. When the file does not exist, create it from this skill's `templates/decisions.md` first. In plan mode, where every edit but the plan file is blocked, put the rows verbatim in the plan and make appending them the plan's first step after approval, before any code.

6. **Plan and hand off.** Write the plan as plan mode's own output (outside plan mode, as your reply)—no plan document is created in the repository. Each plan step names the decision rows and `file:line` evidence it relies on. Hand off in Korean: 구현 중 계획에서 벗어나는 결정은 `docs/decisions.md`에 한 줄 추가할 것, 머지 게이트는 PR 리뷰.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries — correct a stale entry's referent instead. -->
- Scanners return findings; YOU convert them to questions. A finding without a decision attached is noise.
- Do not serialize the two scanner spawns—submit both before waiting, or the pass takes twice as long.
- Domain unknowns don't live in the repo — scanners on a pure-domain task come back empty. That gap is a question for the user or a `보류:` row, never a reason to scan again.
- A question the user cannot parse defeats the whole pass — the decision gets guessed, not made. Plain words are not enough: a question with nested clauses locks readers out even with zero jargon. One decision per question; 근거 cells stay technical.
- More than 3 questions means the evidence is thin—decide or park, never ask more. Past that, guessed answers become fake requirements.
- The urge to keep "just the raw findings somewhere" is an unknowns file coming back — `docs/decisions.md` rows are the only durable output.
- A row that repeats what `AGENTS.md` already says belongs in `AGENTS.md`, not here.
- A plan written from the prompt alone reproduces the prompt's blind spots.
