# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A shared Claude Code skill and agent that other projects consume as a git submodule mounted at `.claude/shared/`, wired up by `install.sh` (relative symlinks `.claude/skills/blindspot-pass` and `.claude/agents/codebase-scanner.md`, pruning of dangling links into `.claude/shared` that removed skills or agents left behind, a SessionStart hook running `hooks/mandate.sh`, and a `@.claude/shared/MANDATE.md` import in the consumer's CLAUDE.md). It keeps only what vanilla Claude Code lacks: before an implementation plan, `blindspot-pass` turns unknown unknowns into at most 4 decidable questions (two parallel `codebase-scanner` lenses, one AskUserQuestion call), and every decision becomes one row in the consumer's `docs/decisions.md`, shared through git so no session asks it again. There are no other deliverables and no PR merge gate: finished, verified work is committed directly on the default branch (`main`) and pushed, with the summary and review points in the commit message body.

## Test

```bash
bash test/check.sh
```

Covers: mandate hook output contains `# Blindspot Mandate`, `blindspot-pass`, and `docs/decisions.md`; `MANDATE.md` ≤ 10 lines; YAML frontmatter lint (`name`, `description`) across exactly 2 files (1 skill + 1 agent); skill↔agent `subagent_type` reference integrity in both directions (every referenced agent exists, every agent is referenced); decisions table contract (the template's title, header, and separator, no shipped rows; `SKILL.md` names the template and the same column order); `install.sh` on a fake consumer upgrading from an older version in a temp dir (stale links into `.claude/shared` pruned, the project's own skill and outside link kept, exactly 2 shared links, no `docs/` created, settings.json / CLAUDE.md / links unchanged on the second run); names retired with the full lifecycle (listed in `test/check.sh`) absent from `skills/`, `agents/`, `MANDATE.md`, `install.sh`, `README.md`, and this file; this repo's `docs/decisions.md` keeps the template header, and every row starts with `| 20` and has six cells.

## Conventions

- Model-facing instruction files (`SKILL.md`, `agents/*.md`, `MANDATE.md`): English. User-facing deliverables the skill generates, and `README.md`: Korean. Do not mix.
- Templates (`skills/*/templates/*`): deliverable text Korean; instruction comments addressed to the generating model (`<!-- -->`) English. Cross-referenced identifiers (column names such as 결정 주체, values such as 자체 and `보류:`, lens names) keep their established form. The skill writes rows by column order, so the template's table header is a contract (checked by `test/check.sh`). A template ships no example rows — grep would count them as decisions.
- Template ownership: `templates/decisions.md` belongs to blindspot-pass. A skill that needs another skill's template names it by skill; templates are never duplicated.
- Skill frontmatter `description` is the trigger condition — always starts with "Use when ..." or "Use before ...".
- Every SKILL.md has a `## Gotchas` section. Append recurring failure points there; never delete entries. When a structural change makes an entry factually wrong, rewrite it to name the new referent — correcting a stale referent is not deletion.
- Agents are read-only by design — they never edit files. Keep `tools` minimal (`Bash` only where git inspection is required, with read-only instructions in the body). Pin a cost-appropriate `model` in frontmatter: `sonnet` for exploration (codebase-scanner), `haiku` for purely mechanical checkers; inherit the session model only for judgment that gates a merge.
- Deliverable path contract baked into the skill, the agent, and MANDATE: `docs/decisions.md` at the consumer's project root — the only document this workflow creates, made by the skill when it writes its first row, never by `install.sh`. Row contract: 날짜 | 영역 | 결정 | 근거 | 기각한 대안 | 결정 주체, one line, starts with `| 20`, append-only; a row is superseded by a new row whose 근거 names the old row's date. 영역 is frontend, backend, core, or a module name; 결정 주체 is 사용자 or 자체.
- The question cap (4 in one AskUserQuestion call — the tool's per-call maximum), parking as `보류:` rows, and plan-mode handling (rows ride in the plan and are appended right after approval) live in `skills/blindspot-pass/SKILL.md`. `MANDATE.md` holds only the five session rules and stays ≤ 10 lines because consumers receive it twice (hook + @import).

## Consumer contract (breaking-change checklist)

Renaming or moving any of these breaks consumer projects — update `install.sh` + `test/check.sh` + `README.md` together:

- `skills/blindspot-pass/` directory name (= installed skill name, referenced in `MANDATE.md`)
- `agents/codebase-scanner.md` filename (= `subagent_type` value referenced in SKILL.md)
- `hooks/mandate.sh`, `MANDATE.md` paths (referenced by consumer `settings.json` and CLAUDE.md import line)
- `docs/decisions.md` path and its column order (referenced by MANDATE, SKILL.md, the agent, and README)
- `skills/blindspot-pass/templates/decisions.md`

Consumers who re-run `install.sh` lose a removed skill or agent cleanly — the dangling link is pruned. The 2026-09-14 lite cut dropped the earlier "names and counts never change" contract on purpose (see `docs/decisions.md`).

## Design docs

Current behavior is grounded in `docs/decisions.md` — this repo's own decision record, in the same format consumers use. `docs/superpowers/` is past design history (dated design spec and plan pairs from the full-lifecycle era) and `docs/blindspot/` is pre-tier history (two accepted reports and quizzes); no skill reads either.
