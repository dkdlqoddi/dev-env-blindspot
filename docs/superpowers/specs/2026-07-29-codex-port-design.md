# Codex-Only Blindspot Environment Design

## Purpose

Port the repository's active Claude Code development environment to Codex while preserving the observable blindspot lifecycle:

1. clarify requirements before implementation;
2. expose unknown unknowns through evidence-backed parallel scans;
3. produce a standalone design explanation;
4. record non-obvious implementation decisions when they happen;
5. produce a change report and block completion until the user passes the pre-merge quiz.

The port lives on a local `codex` branch based on `main` commit `f2d473d`. It is Codex-only. It does not retain a second Claude-compatible runtime path.

## Scope

### In scope

- Replace repository guidance with Codex-native `AGENTS.md` guidance.
- Convert the five Claude agent definitions into five Codex custom-agent TOML files.
- Rewrite active skill instructions that name Claude-only tools, invocation syntax, paths, models, or subagent parameters.
- Replace the consumer installation layout, hook registration, and fallback guidance with Codex-native equivalents.
- Rewrite the active README and repository checks for Codex.
- Preserve the five lifecycle skills, their outputs, templates, readability rules, and merge quiz gate.

### Out of scope

- Rewriting dated files under `docs/superpowers/` or `docs/blindspot/` that record historical Claude implementation work.
- Packaging the repository as a Codex plugin.
- Adding CI, Windows-native support, MCP servers, or authenticated model-driven end-to-end tests.
- Changing deliverable names, Korean writing standards, question policy, or quiz scoring behavior.

## Alternatives Considered

### Selected: native Codex source

Keep the repository itself in the format Codex consumes. Skills remain authorable source folders, while agents become Codex TOML definitions. This keeps installation transparent and makes active files directly reviewable.

### Rejected: convert Claude files during installation

An installer-time transpiler could preserve the old source format, but every install would depend on a second representation layer. That would hide behavior changes inside conversion code and make validation harder.

### Rejected: package as a plugin

A plugin would improve distribution, but it changes the current git-submodule workflow and expands the scope. Project custom-agent installation is also a separate concern from the reusable skill bundle.

## Behavior-Equivalence Review

The first proposed mapping was not equivalent. It relied on symlinked custom-agent TOML files, a weak `AGENTS.md` pointer, and unspecified model and interaction fallbacks. The corrected design below closes those gaps.

| Existing observable behavior | Codex implementation | Equivalence condition |
|---|---|---|
| Five skills are installed separately and coexist with unrelated project skills. | Link each shared skill into `.agents/skills/<skill>`. | All five links resolve, and unrelated names remain untouched. |
| Five named agents carry focused read-only instructions. | Copy five real TOML files into `.codex/agents/`. | Codex loads every unique `name`, and each skill reference resolves to one role. |
| A session-start hook injects `MANDATE.md`. | Merge one unfiltered `SessionStart` command into `.codex/hooks.json`. | The command resolves from the Git root and its stdout equals `MANDATE.md`. |
| A checked-in instruction file is a fallback when the hook does not run. | Embed the complete mandate in a managed block in root `AGENTS.md`. | Existing consumer guidance is preserved and the block is updated idempotently. |
| A same-directory override can replace normal guidance. | If `AGENTS.override.md` exists, maintain the same mandate block there as well. | The fallback remains model-visible under Codex precedence rules. |
| Requirements interview asks one Korean question per turn. | Use one `request_user_input` question when that UI exists; otherwise end the turn with one direct Korean question. | One decision per turn, architecture impact first, with no auto-resolution. |
| Skills delegate to named agents, including parallel scan roles. | Select the named custom-agent profile. If selection is unavailable, spawn a general subagent with that profile's full instructions and task input. | Role instructions, evidence contract, and parent synthesis remain unchanged. |
| Mechanical roles use a cheaper model, exploration uses stronger reasoning, and merge analysis inherits the session model. | Pin Terra at low effort for mechanical roles, Terra at medium effort for exploration, and omit model fields for change analysis. | The cost/quality role split remains explicit. |
| Agents do not edit source files. | Use `sandbox_mode = "read-only"` plus explicit no-write instructions, except the check runner. | Read-only roles cannot mutate the workspace even if their prompt drifts. |
| The check runner executes standard tests that may create local artifacts. | Give only `check_runner` workspace-write sandboxing with strict instructions against source edits and external side effects. | Test caches/build outputs can be created, while source changes remain prohibited by instruction and verification. |
| Domain research uses the web when available and labels a fallback when it is not. | Inherit Codex web capability and retain the exact unavailable-web fallback. | No URL is fabricated when web search is unavailable. |
| Report mode cannot declare completion before a perfect quiz. | Preserve the report, quiz generator, checker, and user-confirmation gate verbatim apart from installed paths. | A completion claim remains forbidden before explicit user confirmation. |

Codex introduces unavoidable operational differences: project hooks require trust, custom agents do not expose Claude's frontmatter tool allowlist, model identifiers differ, and runtime concurrency or web access may be restricted by user or administrator policy. These differences must be documented and must not silently weaken the lifecycle rules.

## Repository Layout

The active source tree becomes:

```text
AGENTS.md
MANDATE.md
README.md
install.sh
hooks/mandate.sh
agents/
  change_analyzer.toml
  check_runner.toml
  codebase_scanner.toml
  doc_verifier.toml
  domain_researcher.toml
skills/
  blindspot-flow/
  blindspot-pass/
  explainer/
  requirements-interview/
  work-report/
test/check.sh
```

Templates and `skills/work-report/scripts/quiz_check.py` remain unchanged unless a path-only correction is required.

## Consumer Installation

Consumers mount the repository at `.codex/shared` and run `.codex/shared/install.sh`.

The resulting consumer layout is:

```text
.codex/
  shared/                    # git submodule
  agents/*.toml              # real installed files copied from shared source
  hooks.json                 # existing JSON preserved; one hook merged
.agents/
  skills/<name>              # relative links to .codex/shared/skills/<name>
AGENTS.md                    # consumer content plus managed mandate block
AGENTS.override.md           # updated only when already present
```

Custom-agent TOML files are copied instead of symlinked because the Codex documentation explicitly guarantees symlink following for skills but not for custom-agent files. Re-running the installer refreshes the five reserved role names. Other agent files and skills remain untouched.

The hook command is:

```text
bash "$(git rev-parse --show-toplevel)/.codex/shared/hooks/mandate.sh"
```

It has no matcher so it applies to every supported session-start source, including startup, resume, clear, and compact. The README explains that Codex may skip the hook until the project and exact hook definition are trusted through `/hooks`. The managed `AGENTS.md` block remains the startup fallback even before hook trust.

## Skill Interaction Rules

The port changes host-specific mechanics without changing workflow decisions.

- Explicit skill invocation uses `$requirements-interview`, `$blindspot-pass`, `$explainer`, `$work-report`, or `$blindspot-flow`.
- Implicit invocation still relies on each `description` and the mandatory task-to-skill mapping.
- A named custom agent must be selected by its TOML `name`, not merely reused as a task label.
- When the runtime cannot select a custom profile, the parent reads the installed TOML and includes its complete `developer_instructions` in a general subagent task.
- Independent work is submitted together and uses all runtime concurrency available. A platform limit may queue excess roles, but the parent must not serialize them voluntarily.
- `requirements-interview` asks exactly one question per turn. Other workflows retain their existing question caps and checkpoint batching instead of inheriting that rule globally.
- `request_user_input` is used only when available and compatible with the number of meaningful options. Direct Korean questions are the fallback.

## Custom-Agent Policy

| Agent | Model policy | Sandbox | Preserved contract |
|---|---|---|---|
| `codebase_scanner` | `gpt-5.6-terra`, medium | read-only | One lens, 3–8 findings, `path:line`, no edits. |
| `domain_researcher` | `gpt-5.6-terra`, medium | read-only | Web evidence, 3–8 findings, explicit no-web fallback, no side effects. |
| `doc_verifier` | `gpt-5.6-terra`, low | read-only | Four document checks, PASS or numbered Korean issues, no fixes. |
| `change_analyzer` | inherit parent | read-only | Diff/plan/risk/test/quiz analysis, Korean output, no edits. |
| `check_runner` | `gpt-5.6-terra`, low | workspace-write | Standard checks once, distilled failures, no source edits or external actions. |

Every TOML contains `name`, `description`, and `developer_instructions`. Read-only behavior remains stated in the instructions even when sandbox policy also enforces it, because parent runtime overrides and external tools can vary by Codex surface.

## Error Handling

- Missing `.codex/shared/skills` stops installation with the expected mount path.
- Missing Python 3 stops installation with a concise manual recovery description.
- Invalid or non-object `.codex/hooks.json` stops before replacing its content.
- Existing unrelated hook groups and top-level JSON fields are preserved.
- The same blindspot hook or managed guidance block is updated instead of duplicated.
- Existing consumer `AGENTS.md` and `AGENTS.override.md` text outside managed markers is preserved byte-for-byte where practical.
- A custom-agent role that Codex cannot select falls back to a fully instructed general subagent, not to an unqualified task label.
- A check blocked by sandbox policy is reported as `실행 불가`, not as a product test failure.
- Missing web access uses the existing `출처: 모델 지식 (웹 접근 불가)` label and never fabricates a URL.
- Lower runtime concurrency queues work without changing lens coverage or parent-side synthesis.

## Verification Design

`bash test/check.sh` remains the single repository check and must cover:

1. `hooks/mandate.sh` output exactly matches `MANDATE.md` and names all five skills.
2. All five `SKILL.md` files have matching names, non-empty trigger descriptions, and resolvable referenced templates/scripts.
3. All five agent TOML files have unique names and the required fields; every named role reference resolves and no installed role is orphaned.
4. The four copies of the `25 어절` readability standard remain present.
5. A fake Git consumer with pre-existing unrelated skills, agents, hooks, `AGENTS.md`, and `AGENTS.override.md` retains that content after installation.
6. Running the installer twice produces byte-identical managed files and exactly one hook and mandate block.
7. All five skill links resolve, all five custom-agent TOML files are real files, and installed support assets remain reachable.
8. The hook command works from a nested consumer directory and returns the canonical mandate.
9. Active runtime files contain none of the retired Claude paths, tool names, model names, or invocation syntax; dated historical documents are excluded from this tripwire.
10. `quiz_check.py` accepts the shipped templates and rejects temporary over-limit question, explanation, summary, and option fixtures.
11. When `codex` is available, `codex --strict-config debug prompt-input` loads the fake consumer without configuration errors and exposes the skill metadata and mandate context. This local parser/discovery smoke test does not call a model.

An authenticated `codex exec` test is deliberately not a deterministic merge gate because authentication, model access, network access, hook trust, and generated wording vary between environments.

## Completion Criteria

- The active repository is Codex-only and the dated historical records are unchanged.
- `codex` exists as the working branch based on the reviewed `main` commit.
- The installer is idempotent and preserves unrelated consumer configuration.
- The deterministic check suite passes.
- A fresh Codex parser/discovery smoke check passes in a disposable consumer.
- A separate review finds no Critical or Important behavior-equivalence gaps.
- No merge or completion claim is made until the repository's own pre-merge reporting and quiz policy has been satisfied where that policy applies.
