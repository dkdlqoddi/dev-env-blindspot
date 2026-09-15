# Blindspot Mandate

Injected into every session of this project. These rules are not optional.

1. Before writing an implementation plan for a non-trivial task, invoke `$blindspot-pass`. Trivial (a few files, clear requirements) → skip it.
2. Decisions live in `docs/decisions.md`, append-only, one line per row. Never re-ask what a row answers; cite it.
3. A mid-implementation decision that deviates from the plan, or chooses between options the plan does not settle, gets a row at decision time. Reversible → take the conservative option and log it; irreversible or destructive → ask first.
4. This workflow creates no other document under `docs/`. Summaries and review points go in the PR body; the merge gate is PR review.
5. `$blindspot-pass` delegates exploration to `codebase_scanner`; raw scan output never becomes a repository artifact.
