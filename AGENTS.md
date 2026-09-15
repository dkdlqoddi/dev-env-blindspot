# AGENTS.md

## What this repo is

This repository contains one shared Codex skill and one read-only custom-agent
profile. Consumer projects mount it as a git submodule at `.codex/shared`, then
run `install.sh`. The installer links `blindspot-pass` into `.agents/skills`,
copies `codebase_scanner.toml` into `.codex/agents`, merges a SessionStart hook
into `.codex/hooks.json`, and maintains the complete mandate in managed blocks
inside root `AGENTS.md` and an existing `AGENTS.override.md`.

Blindspot-lite keeps only two capabilities beyond an ordinary Codex workflow:
turn unknown unknowns into at most three decidable questions before an
implementation plan, and append every decision to `docs/decisions.md` so later
sessions do not ask it again. It creates no other runtime document. PR review is
the merge gate.

## Test

Run the repository check from the root:

```bash
bash test/check.sh
```

The check covers the Codex discovery layout, the one-skill/one-agent contract,
the three-question workflow, the decision table, installer migration and
idempotency, consumer-file preservation, hook behavior from nested directories,
converted historical records, and native offline Codex discovery when the local
CLI supports it.

## Conventions

- Model-facing files (`SKILL.md`, `agents/*.toml`, `MANDATE.md`) are English.
  User-facing generated content and `README.md` are Korean.
- Skill frontmatter `description` is the trigger condition and begins with
  `Use when` or `Use before`.
- Every `SKILL.md` has a `## Gotchas` section. Append recurring failure points;
  do not delete entries merely because the current change avoids them.
- `codebase_scanner` is read-only in both its sandbox and instructions. It uses
  `gpt-5.6-terra` with medium reasoning because identifying missing decisions is
  judgment-heavy exploration.
- `docs/decisions.md` is the only runtime document. Its row contract is
  `날짜 | 영역 | 결정 | 근거 | 기각한 대안 | 결정 주체`, one line per decision,
  append-only. A new row supersedes an old row by citing its date.
- The question cap is three in one `request_user_input` call. If that tool is
  unavailable, ask the same batch directly in Korean rather than adding another
  round.
- `MANDATE.md` stays at ten lines or fewer because consumers receive it through
  both project guidance and the SessionStart hook.

## Consumer contract

Changing any item below is breaking; update `install.sh`, `test/check.sh`, and
`README.md` together:

- `skills/blindspot-pass/` and `.agents/skills/blindspot-pass`
- `agents/codebase_scanner.toml` and `.codex/agents/codebase_scanner.toml`
- `hooks/mandate.sh`, `MANDATE.md`, and `.codex/hooks.json`
- managed mandate markers in `AGENTS.md` and an existing `AGENTS.override.md`
- `docs/decisions.md` and `skills/blindspot-pass/templates/decisions.md`

The installer owns only the named skill, named agent profile, exact hook command,
and text inside its mandate markers. It preserves unrelated consumer content.

## Historical records

`docs/blindspot/` contains converted records from earlier iterations. No runtime
skill reads them. Current behavior is grounded in `docs/decisions.md` and the
active files above.
