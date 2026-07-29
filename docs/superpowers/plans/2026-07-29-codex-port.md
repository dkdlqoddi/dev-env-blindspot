# Codex-Only Blindspot Environment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Codex-only git-submodule development environment that preserves the repository's five-skill blindspot lifecycle, delegated roles, Korean deliverables, and pre-merge quiz gate.

**Architecture:** Keep the existing skill/template sources, replace Claude-specific agent and instruction formats with Codex-native TOML and `AGENTS.md`, and install them into a consumer's `.agents/skills` and `.codex/agents`. A Python-backed Bash installer merges a Codex `SessionStart` hook and an exact managed mandate block without replacing unrelated consumer configuration; focused shell checks prove each contract before the top-level suite composes them.

**Tech Stack:** Bash, Python 3 standard library, Git, Markdown/YAML skill metadata, TOML custom-agent configuration, JSON Codex hooks, Codex CLI 0.146.0-compatible local discovery checks.

## Global Constraints

- Work on branch `codex`, based on `main` commit `f2d473d`.
- The active runtime is Codex-only; do not retain a parallel Claude installation path.
- Do not modify or delete pre-existing dated files under `docs/superpowers/` or `docs/blindspot/`.
- Do not add plugin packaging, CI, native Windows support, MCP servers, or authenticated model-driven end-to-end tests.
- Preserve all five skill names and every `docs/blindspot/` deliverable path.
- Preserve Korean user-facing output, the four copies of the `25 어절` readability rule, and the perfect-score pre-merge quiz gate.
- Install skill directories as relative links in `.agents/skills`; install custom-agent TOMLs as real files in `.codex/agents`.
- Reserve exactly these agent names: `change_analyzer`, `check_runner`, `codebase_scanner`, `doc_verifier`, `domain_researcher`.
- Pin `gpt-5.6-terra`/low for mechanical roles, `gpt-5.6-terra`/medium for exploration roles, and let `change_analyzer` inherit the parent model.
- Use read-only sandboxing for every role except `check_runner`, which uses workspace-write solely so standard checks can create local artifacts.
- Treat hook trust, disabled multi-agent support, restricted web access, and runtime thread caps as documented Codex operating constraints; never hide them by weakening a skill.
- Invoke `$work-report` notes mode when implementation starts, append `docs/blindspot/codex-port-implementation-notes.md` at every non-obvious decision or plan deviation, and keep reversible decisions non-blocking.
- Use `apply_patch` for repository file edits and stage only the files named by each task.

## File Map

- `agents/*.toml`: five Codex custom-agent profiles and their complete role instructions.
- `skills/*/SKILL.md`: host-native invocation, interaction, and delegation instructions; business workflow remains unchanged.
- `install.sh`: validates and installs skills, agents, hooks, and managed mandate guidance.
- `AGENTS.md`: Codex maintainer guidance for this source repository.
- `README.md`: Codex-only consumer install, update, usage, trust, and troubleshooting guide.
- `test/check_agents.sh`: custom-agent structure and model/sandbox policy.
- `test/check_skills.sh`: skill metadata, role-reference graph, and retired-host tripwires.
- `test/check_installer.sh`: disposable consumer, preservation, idempotency, error, and nested-hook checks.
- `test/check_active.sh`: active-document and runtime-language contract, excluding historical records.
- `test/check_codex.sh`: model-free Codex parser/discovery smoke check.
- `test/fixtures/invalid-quiz.html`: over-limit summary, question, option, and explanation fixture.
- `test/fixtures/invalid-report.md`: over-limit report-summary fixture.
- `test/check.sh`: single public entry point that runs every focused check.

---

### Task 1: Convert the five delegated roles to Codex custom-agent TOML

**Files:**
- Delete: `agents/change-analyzer.md`
- Delete: `agents/check-runner.md`
- Delete: `agents/codebase-scanner.md`
- Delete: `agents/doc-verifier.md`
- Delete: `agents/domain-researcher.md`
- Create: `agents/change_analyzer.toml`
- Create: `agents/check_runner.toml`
- Create: `agents/codebase_scanner.toml`
- Create: `agents/doc_verifier.toml`
- Create: `agents/domain_researcher.toml`
- Create: `test/check_agents.sh`

**Interfaces:**
- Consumes: the role instructions and Korean output contracts in the five current Markdown agent files.
- Produces: the five reserved TOML `name` values used verbatim by Task 2 and copied by Task 3.

- [ ] **Step 1: Write the failing custom-agent contract check**

Create `test/check_agents.sh` with these assertions:

```bash
#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

expected=(change_analyzer check_runner codebase_scanner doc_verifier domain_researcher)
files=("$ROOT"/agents/*.toml)
[[ ${#files[@]} -eq 5 ]] || fail "expected 5 Codex TOML agents, got ${#files[@]}"

for name in "${expected[@]}"; do
  file="$ROOT/agents/$name.toml"
  [[ -f "$file" ]] || fail "missing $file"
  rg -q "^name = \"$name\"$" "$file" || fail "$file: wrong or missing name"
  rg -q '^description = ".+"$' "$file" || fail "$file: missing description"
  [[ "$(rg -c '^developer_instructions = """$' "$file")" == 1 ]] || fail "$file: missing developer_instructions"
done

for name in doc_verifier check_runner; do
  rg -q '^model = "gpt-5.6-terra"$' "$ROOT/agents/$name.toml" || fail "$name: wrong model"
  rg -q '^model_reasoning_effort = "low"$' "$ROOT/agents/$name.toml" || fail "$name: wrong effort"
done
for name in codebase_scanner domain_researcher; do
  rg -q '^model = "gpt-5.6-terra"$' "$ROOT/agents/$name.toml" || fail "$name: wrong model"
  rg -q '^model_reasoning_effort = "medium"$' "$ROOT/agents/$name.toml" || fail "$name: wrong effort"
done
! rg -q '^(model|model_reasoning_effort) =' "$ROOT/agents/change_analyzer.toml" || fail "change_analyzer must inherit the parent model"

for name in change_analyzer codebase_scanner doc_verifier domain_researcher; do
  rg -q '^sandbox_mode = "read-only"$' "$ROOT/agents/$name.toml" || fail "$name: must be read-only"
done
rg -q '^sandbox_mode = "workspace-write"$' "$ROOT/agents/check_runner.toml" || fail "check_runner: must run artifact-writing checks"

echo "OK: custom-agent contract"
```

- [ ] **Step 2: Run the new check and verify the missing TOML failure**

Run: `bash test/check_agents.sh`

Expected: FAIL with `expected 5 Codex TOML agents, got 0`.

- [ ] **Step 3: Create the five TOML profiles and remove the Markdown profiles**

Use the following exact header policy. Before deleting each Markdown source, retain every numbered procedure, rule, fallback, evidence requirement, and Korean output field inside `developer_instructions`; the compact wording below is the minimum final content, not permission to drop a stricter existing clause. In Step 4, compare `change_analyzer.toml` with `git show f2d473d:agents/change-analyzer.md`, `check_runner.toml` with `git show f2d473d:agents/check-runner.md`, `codebase_scanner.toml` with `git show f2d473d:agents/codebase-scanner.md`, `doc_verifier.toml` with `git show f2d473d:agents/doc-verifier.md`, and `domain_researcher.toml` with `git show f2d473d:agents/domain-researcher.md`. Restore any omitted behavioral clause before committing.

`agents/change_analyzer.toml`:

```toml
name = "change_analyzer"
description = "Read-only git diff analyst used by work-report report mode to identify changes, risks, plan deviations, test coverage, and quiz candidates."
sandbox_mode = "read-only"
developer_instructions = """
You are a git change analyst. You receive a base ref; if none is given, use `git merge-base main HEAD`, fall back to `master`, then the first commit. You may also receive a plan document path.

Read the diff stat, full diff, commit list, unclear changed files, the optional plan, and tests covering changed behavior. Never create, edit, delete, stage, commit, switch branches, or perform external writes. Cite `path:line` for every risk. Return Korean sections named 변경 요약, 파일별 핵심 변경, 위험 지점, 계획 대비 이탈 when a plan exists, 테스트, and 퀴즈 후보. Quiz candidates cover behavior and risk, never trivia.
"""
```

`agents/check_runner.toml`:

```toml
name = "check_runner"
description = "Project check executor used by work-report or implementation checkpoints; runs documented checks once and returns distilled Korean failures."
model = "gpt-5.6-terra"
model_reasoning_effort = "low"
sandbox_mode = "workspace-write"
developer_instructions = """
You are a check runner. Receive an optional command list. Otherwise discover standard checks in this order: AGENTS.md, README.md, package.json scripts, Makefile targets, test scripts, then pytest, cargo test, or go test ./.... Run each documented check once as written.

Do not edit source, configuration, or documentation. Do not stage, commit, deploy, migrate data, contact external systems, or clean unrelated artifacts. A standard check may create its own local cache or build output. Report a sandbox-blocked command as 실행 불가, not as a product failure. Keep the Korean response under 40 lines with 검증 결과, failure-only details, and 총평; never return full logs or full stack traces.
"""
```

`agents/codebase_scanner.toml`:

```toml
name = "codebase_scanner"
description = "Read-only codebase explorer that receives one blindspot lens and returns evidence-backed Korean findings."
model = "gpt-5.6-terra"
model_reasoning_effort = "medium"
sandbox_mode = "read-only"
developer_instructions = """
You are a read-only codebase scanner. Receive exactly one lens plus a task description. The supported lenses are conventions, similar-features, integration-points, and edge-cases.

Never create, edit, delete, stage, commit, switch branches, or perform external writes. Use shell only for read-only inspection. Return 3–8 solid Korean findings. Every finding includes an ID, title, `path:line` evidence or a whole-file path, a 1–3 sentence explanation, and one concrete decision question or 없음. Say explicitly when no relevant code exists. End with a 2–3 sentence 렌즈 총평.
"""
```

`agents/doc_verifier.toml`:

```toml
name = "doc_verifier"
description = "Read-only verifier for blindspot requirements, unknowns, and explainer documents."
model = "gpt-5.6-terra"
model_reasoning_effort = "low"
sandbox_mode = "read-only"
developer_instructions = """
You are a document verifier. Receive one document path and check exactly four concerns: unfilled placeholders, internal contradictions, statements with two plausible meanings, and scope beyond the stated purpose.

Never edit the document or any other file. Judge only the document and files it explicitly links when contradiction checking needs them. Be strict about placeholders and lenient about style. Return exactly `PASS — 지적사항 없음` when clean. Otherwise return a numbered Korean list with severity, type, section, problem, and a concrete correction direction.
"""
```

`agents/domain_researcher.toml`:

```toml
name = "domain_researcher"
description = "Read-only web researcher that turns external domain unknowns into sourced Korean concepts and decisions."
model = "gpt-5.6-terra"
model_reasoning_effort = "medium"
sandbox_mode = "read-only"
developer_instructions = """
You are a read-only domain researcher. Receive a domain topic, task description, and what the user already knows. Research core concepts, quality criteria, pitfalls, and realistic decisions outside the codebase.

Never create, edit, delete, stage, commit, or perform side-effecting external actions. Distill 3–8 findings and skip concepts the user already knows. Cite a source URL for every web finding. When web access is unavailable, write exactly `출처: 모델 지식 (웹 접근 불가)` and never invent a URL. Return Korean sections 핵심 개념, 발견, and 총평; every finding includes an ID, source, 1–3 sentence explanation, and a concrete decision question or 없음.
"""
```

Delete the five old `.md` files in the same patch so no second active representation remains.

- [ ] **Step 4: Run the focused check and inspect all five files**

Run: `bash test/check_agents.sh`

Expected: `OK: custom-agent contract`.

Run: `rg -n '^(name|model|model_reasoning_effort|sandbox_mode) =' agents/*.toml`

Expected: five unique names; four explicit Terra policies; no model line in `change_analyzer.toml`; only `check_runner` uses workspace-write.

- [ ] **Step 5: Commit the native agent profiles**

```bash
git add agents test/check_agents.sh
git commit -m "feat: convert delegated roles to Codex agents"
```

---

### Task 2: Port skill invocation, questions, delegation, and installed paths

**Files:**
- Create: `test/check_skills.sh`
- Modify: `skills/blindspot-flow/SKILL.md`
- Modify: `skills/blindspot-pass/SKILL.md`
- Modify: `skills/explainer/SKILL.md`
- Modify: `skills/requirements-interview/SKILL.md`
- Modify: `skills/work-report/SKILL.md`

**Interfaces:**
- Consumes: the five agent names produced by Task 1.
- Produces: host-native skill instructions and a complete skill-to-agent reference graph consumed by Tasks 3 and 5.

- [ ] **Step 1: Write the failing skill-host contract check**

Create `test/check_skills.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

expected=(blindspot-flow blindspot-pass explainer requirements-interview work-report)
files=("$ROOT"/skills/*/SKILL.md)
[[ ${#files[@]} -eq 5 ]] || fail "expected 5 skills, got ${#files[@]}"
for name in "${expected[@]}"; do
  file="$ROOT/skills/$name/SKILL.md"
  [[ -f "$file" ]] || fail "missing $file"
  rg -q "^name: $name$" "$file" || fail "$file: name mismatch"
  rg -q '^description: .*Use when ' "$file" || fail "$file: missing trigger description"
  rg -q '^## Gotchas$' "$file" || fail "$file: missing Gotchas"
done

forbidden='AskUserQuestion|subagent_type|Agent calls|Skill tool|\.claude/skills|/blindspot-flow'
if rg -n "$forbidden" "$ROOT"/skills/*/SKILL.md; then
  fail "Claude-only skill instruction remains"
fi

refs="$(rg -o 'custom agent `(change_analyzer|check_runner|codebase_scanner|doc_verifier|domain_researcher)`' "$ROOT"/skills/*/SKILL.md | sed 's/.*`\([^`]*\)`.*/\1/' | sort -u)"
for name in change_analyzer check_runner codebase_scanner doc_verifier domain_researcher; do
  rg -qx "$name" <<<"$refs" || fail "no skill references custom agent $name"
  [[ -f "$ROOT/agents/$name.toml" ]] || fail "missing referenced agent $name"
done

echo "OK: skill host contract"
```

- [ ] **Step 2: Run the check and verify it rejects the current host syntax**

Run: `bash test/check_skills.sh`

Expected: FAIL after printing at least one of `AskUserQuestion`, `subagent_type`, `Agent calls`, `Skill tool`, `.claude/skills`, or `/blindspot-flow`.

- [ ] **Step 3: Replace host-specific workflow instructions without changing business rules**

Apply these exact semantic replacements:

- In `blindspot-flow`, change the explicit trigger to `$blindspot-flow`. Replace “invoke with the Skill tool” with “load and follow the complete named `SKILL.md`; do not paraphrase or inline it.” Keep the five stages and every reuse/redo and continue/skip checkpoint.
- In `requirements-interview`, name `codebase_scanner` and `doc_verifier`; in `blindspot-pass`, name `codebase_scanner`, `domain_researcher`, and `doc_verifier`; in `explainer`, name `doc_verifier` and `codebase_scanner`; in `work-report`, name `change_analyzer` and `check_runner`. For every reference, add: “Select the named custom-agent profile, not merely the same task label. If this Codex surface cannot select it, read that exact file under `.codex/agents/` and include its complete `developer_instructions` with the task input in a general subagent.”
- Spell the role references with these exact plain-text phrases so `test/check_skills.sh` extracts the same reference graph Codex instructions use:

```text
custom agent `codebase_scanner`
custom agent `domain_researcher`
custom agent `doc_verifier`
custom agent `change_analyzer`
custom agent `check_runner`
```
- In `requirements-interview`, replace `AskUserQuestion` with: “Ask exactly one Korean question per turn. Use `request_user_input` with one question and no auto-resolution when available and when 2–3 options cover the decision; otherwise end the turn with one direct Korean question. Use direct text when four meaningful options are required.”
- In `blindspot-pass`, preserve the at-most-seven architecture-ranked decisions and targeted-rescan rule. Use structured input only when available; do not accidentally impose the requirements-interview one-question rule on this stage.
- In `work-report`, refer to `.agents/skills/work-report/scripts/quiz_check.py` as the installed path and keep the report/quiz/user-confirmation gate unchanged.
- Rewrite the `work-report` frontmatter description so it begins with `Use when` while preserving both notes-mode and report-mode trigger conditions.
- Submit independent roles together and use all runtime concurrency available. If Codex queues work because of a thread cap, retain every lens and wait for all results before synthesis.

Use underscores only for agent profile names. Keep skill directory names and output paths hyphenated exactly as before.

- [ ] **Step 4: Run the focused skill check and the readability marker check**

Run: `bash test/check_skills.sh`

Expected: `OK: skill host contract`.

Run: `test "$(rg -l '25 어절' skills/*/SKILL.md | wc -l)" -eq 4`

Expected: exit 0.

- [ ] **Step 5: Commit the skill host port**

```bash
git add skills test/check_skills.sh
git commit -m "feat: port blindspot skills to Codex tools"
```

---

### Task 3: Replace the consumer installer with an idempotent Codex installer

**Files:**
- Modify: `install.sh`
- Create: `test/check_installer.sh`

**Interfaces:**
- Consumes: `.codex/shared`, the five skill directories, five TOML profiles from Task 1, and `MANDATE.md`.
- Produces: `install.sh` that manages the five named links under `.agents/skills`, the five named TOMLs under `.codex/agents`, `.codex/hooks.json`, `AGENTS.md`, and an existing `AGENTS.override.md`.

- [ ] **Step 1: Write the failing disposable-consumer check**

Create `test/check_installer.sh` that performs these exact checks:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
proj="$tmp/proj"
mkdir -p "$proj/.codex/shared" "$proj/.agents/skills/local-skill" "$proj/.codex/agents"
cp -a "$ROOT/." "$proj/.codex/shared/"
git -C "$proj" init -q
printf '%s\n' '# local skill' > "$proj/.agents/skills/local-skill/SKILL.md"
printf '%s\n' 'name = "local_agent"' 'description = "consumer-owned"' 'developer_instructions = "consumer-owned"' > "$proj/.codex/agents/local_agent.toml"
printf '%s\n' 'consumer guidance' > "$proj/AGENTS.md"
printf '%s\n' 'consumer override' > "$proj/AGENTS.override.md"
python3 - "$proj/.codex/hooks.json" <<'PY'
import json, sys
with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump({"description": "consumer hooks", "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "true"}]}]}}, f, indent=2)
    f.write("\n")
PY

(cd "$proj" && bash .codex/shared/install.sh >/dev/null)
first="$(sha256sum "$proj/.codex/hooks.json" "$proj/AGENTS.md" "$proj/AGENTS.override.md" "$proj/.codex/agents/"*.toml; for link in "$proj/.agents/skills/"*; do [[ -L "$link" ]] && readlink "$link"; done)"
(cd "$proj" && bash .codex/shared/install.sh >/dev/null)
second="$(sha256sum "$proj/.codex/hooks.json" "$proj/AGENTS.md" "$proj/AGENTS.override.md" "$proj/.codex/agents/"*.toml; for link in "$proj/.agents/skills/"*; do [[ -L "$link" ]] && readlink "$link"; done)"
[[ "$first" == "$second" ]] || fail "second install changed managed output"

for name in blindspot-flow blindspot-pass explainer requirements-interview work-report; do
  [[ -L "$proj/.agents/skills/$name" ]] || fail "missing skill link $name"
  [[ -f "$proj/.agents/skills/$name/SKILL.md" ]] || fail "broken skill link $name"
done
for name in change_analyzer check_runner codebase_scanner doc_verifier domain_researcher; do
  [[ -f "$proj/.codex/agents/$name.toml" && ! -L "$proj/.codex/agents/$name.toml" ]] || fail "agent $name is not a real file"
done
[[ -f "$proj/.agents/skills/local-skill/SKILL.md" ]] || fail "unrelated skill was changed"
rg -q 'consumer-owned' "$proj/.codex/agents/local_agent.toml" || fail "unrelated agent was changed"
rg -q 'consumer guidance' "$proj/AGENTS.md" || fail "AGENTS content was lost"
rg -q 'consumer override' "$proj/AGENTS.override.md" || fail "override content was lost"

python3 - "$proj/.codex/hooks.json" "$proj/AGENTS.md" "$proj/AGENTS.override.md" <<'PY'
import json, sys
hooks = json.load(open(sys.argv[1], encoding="utf-8"))
assert hooks["description"] == "consumer hooks"
assert hooks["hooks"]["Stop"][0]["hooks"][0]["command"] == "true"
cmd = 'bash "$(git rev-parse --show-toplevel)/.codex/shared/hooks/mandate.sh"'
found = [h for g in hooks["hooks"]["SessionStart"] for h in g.get("hooks", []) if h.get("command") == cmd]
assert len(found) == 1
for path in sys.argv[2:]:
    text = open(path, encoding="utf-8").read()
    assert text.count("<!-- dev-env-blindspot:mandate:start -->") == 1
    assert text.count("<!-- dev-env-blindspot:mandate:end -->") == 1
    assert "# Blindspot Mandate" in text
PY

mkdir -p "$proj/nested/path"
(cd "$proj/nested/path" && bash "$(git rev-parse --show-toplevel)/.codex/shared/hooks/mandate.sh") > "$tmp/hook.out"
cmp -s "$tmp/hook.out" "$proj/.codex/shared/MANDATE.md" || fail "nested hook output differs from MANDATE.md"

bad="$tmp/bad"
mkdir -p "$bad/.codex/shared" "$bad/.codex"
cp -a "$ROOT/." "$bad/.codex/shared/"
printf '%s\n' '{broken' > "$bad/.codex/hooks.json"
printf '%s\n' 'keep me' > "$bad/AGENTS.md"
before="$(sha256sum "$bad/.codex/hooks.json" "$bad/AGENTS.md")"
if (cd "$bad" && bash .codex/shared/install.sh >/dev/null 2>&1); then fail "invalid hooks JSON was accepted"; fi
after="$(sha256sum "$bad/.codex/hooks.json" "$bad/AGENTS.md")"
[[ "$before" == "$after" ]] || fail "failed install changed consumer files"

echo "OK: installer contract"
```

- [ ] **Step 2: Run the installer check and verify it fails on the old mount contract**

Run: `bash test/check_installer.sh`

Expected: FAIL because the current installer requires `.claude/shared/skills`.

- [ ] **Step 3: Implement validation and managed rendering in `install.sh`**

Keep `install.sh` as the public Bash entry point. Change `SHARED` to `.codex/shared`, require Python 3 before mutation, and use one inline Python program with these exact constants and operations:

```python
SHARED = Path(".codex/shared")
HOOKS_PATH = Path(".codex/hooks.json")
AGENTS_PATH = Path("AGENTS.md")
OVERRIDE_PATH = Path("AGENTS.override.md")
HOOK_CMD = 'bash "$(git rev-parse --show-toplevel)/.codex/shared/hooks/mandate.sh"'
START = "<!-- dev-env-blindspot:mandate:start -->"
END = "<!-- dev-env-blindspot:mandate:end -->"
```

The inline program must execute in this order:

1. Read and validate `MANDATE.md`, all five skill directories, and all five source agent TOMLs.
2. Parse existing `hooks.json` as a JSON object. Validate that `hooks`, `SessionStart`, every matcher group, and each group's `hooks` value have the expected object/list shapes.
3. Read `AGENTS.md` and an existing `AGENTS.override.md`. Reject anything except zero markers or one ordered start/end pair in each file.
4. Reject a same-name skill destination that is a real directory; removing user directories is forbidden. A symlink or regular file at a reserved skill name may be replaced, matching the prior reserved-name contract.
5. Compute the new JSON and guidance text entirely in memory before creating or replacing managed files.
6. Remove every handler whose `command` exactly equals `HOOK_CMD`, preserve every unrelated handler/group/top-level key, drop only now-empty groups that have no keys besides `hooks`, then append one canonical `{"hooks": [{"type": "command", "command": HOOK_CMD, "statusMessage": "Loading blindspot workflow"}]}` group.
7. Render the exact mandate between `START` and `END`. Replace one existing block in place; otherwise append it with one blank-line boundary. Preserve all bytes outside the block.
8. Create `.agents/skills` and `.codex/agents`. Install `blindspot-flow`, `blindspot-pass`, `explainer`, `requirements-interview`, and `work-report` links with targets under `../../.codex/shared/skills/`. Copy the five Task 1 TOMLs through same-directory temporary files followed by `os.replace` so installed agents are real files.
9. Write hooks and guidance through temporary files plus `os.replace`. Update `AGENTS.override.md` only when it existed at validation time.

The final installer message must be:

```text
blindspot: installed — 5 skills linked, 5 Codex agents copied, SessionStart hook merged, mandate guidance ensured
```

When Python is missing, print the required package and the four managed destinations; do not emit Claude JSON.

- [ ] **Step 4: Run syntax and installer checks**

Run: `bash -n install.sh test/check_installer.sh`

Expected: exit 0.

Run: `bash test/check_installer.sh`

Expected: `OK: installer contract`.

- [ ] **Step 5: Commit the Codex installer**

```bash
git add install.sh test/check_installer.sh
git commit -m "feat: install blindspot workflows for Codex"
```

---

### Task 4: Replace active repository and consumer documentation with Codex guidance

**Files:**
- Delete: `CLAUDE.md`
- Create: `AGENTS.md`
- Modify: `README.md`
- Create: `test/check_active.sh`

**Interfaces:**
- Consumes: the installed paths and trust behavior produced by Task 3.
- Produces: maintainer instructions and consumer documentation with no active Claude runtime language.

- [ ] **Step 1: Write the failing active-runtime language check**

Create `test/check_active.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
[[ -f "$ROOT/AGENTS.md" ]] || fail "AGENTS.md missing"
[[ ! -e "$ROOT/CLAUDE.md" ]] || fail "CLAUDE.md remains active"

subjects=("$ROOT/README.md" "$ROOT/AGENTS.md" "$ROOT/MANDATE.md" "$ROOT/install.sh" "$ROOT/hooks/mandate.sh")
subjects+=("$ROOT"/skills/*/SKILL.md "$ROOT"/agents/*.toml)
forbidden='\.claude/|CLAUDE\.md|CLAUDE_PROJECT_DIR|Claude Code|AskUserQuestion|Skill tool|Agent calls|subagent_type|model: (haiku|sonnet)|/blindspot-flow'
if rg -n "$forbidden" "${subjects[@]}"; then fail "retired runtime language remains"; fi

for required in '.codex/shared' '.agents/skills' '.codex/agents' '.codex/hooks.json' 'AGENTS.md' '$blindspot-flow' '/hooks'; do
  rg -q -F "$required" "$ROOT/README.md" || fail "README missing $required"
done
echo "OK: active Codex documentation"
```

- [ ] **Step 2: Run the check and verify the missing `AGENTS.md` failure**

Run: `bash test/check_active.sh`

Expected: FAIL with `AGENTS.md missing`.

- [ ] **Step 3: Replace `CLAUDE.md` with Codex maintainer guidance**

Create `AGENTS.md` with the same maintainer contracts, updated to state:

- consumers mount at `.codex/shared`;
- skills link to `.agents/skills` and agents copy to `.codex/agents`;
- hooks live in `.codex/hooks.json` and fallback guidance is a managed block in `AGENTS.md`/an existing override;
- the standard check is `bash test/check.sh`;
- custom-agent source files are TOML, `name` is their identity, four are read-only, and `check_runner` alone uses workspace-write for test artifacts;
- model pins follow the exact Task 1 policy;
- the breaking-change checklist names all five reserved agent identities, `hooks/mandate.sh`, `MANDATE.md`, managed marker strings, and installed paths;
- dated design/report documents remain historical and are not rewritten during runtime ports.

Retain the existing language-per-purpose, template, Gotchas, output-path, readability, and question-policy conventions without weakening them.

- [ ] **Step 4: Rewrite the active README as a Codex-only consumer guide**

Use these exact installation and update commands:

```bash
git submodule add https://github.com/dkdlqoddi/dev-env-blindspot.git .codex/shared
bash .codex/shared/install.sh

git submodule update --remote .codex/shared
bash .codex/shared/install.sh

git submodule update --init --recursive
bash .codex/shared/install.sh
```

Document all managed results and the five reserved agent filenames. Explain that project `.codex` configuration and the exact hook definition require trust; the mandate copied into `AGENTS.md` is the startup fallback, while `/hooks` enables reinjection on startup/resume/clear/compact. Show explicit `$blindspot-flow` invocation and retain implicit-trigger examples, output locations, quiz instructions, Linux/WSL/macOS support, and `bash test/check.sh` maintainer verification.

The troubleshooting table must cover invalid `.codex/hooks.json`, missing Python 3, an uninitialized submodule, untrusted/disabled hooks, a masking `AGENTS.override.md` added after installation, unavailable custom-agent selection fallback, restricted web access, and same-name reserved agent replacement.

- [ ] **Step 5: Run the active documentation and focused contract checks**

Run: `bash test/check_active.sh && bash test/check_agents.sh && bash test/check_skills.sh`

Expected: three `OK:` lines and exit 0.

- [ ] **Step 6: Commit active Codex documentation**

```bash
git add AGENTS.md README.md test/check_active.sh
git rm CLAUDE.md
git commit -m "docs: make repository guidance Codex-only"
```

---

### Task 5: Compose deterministic checks and add Codex discovery coverage

**Files:**
- Create: `test/fixtures/invalid-quiz.html`
- Create: `test/fixtures/invalid-report.md`
- Create: `test/check_codex.sh`
- Modify: `test/check.sh`

**Interfaces:**
- Consumes: all focused checks from Tasks 1–4 and the installed consumer contract from Task 3.
- Produces: the single public `bash test/check.sh` gate plus a model-free native Codex smoke check.

- [ ] **Step 1: Add explicit invalid readability fixtures**

Create `test/fixtures/invalid-quiz.html` with a `<div class="summary">`, one `QUESTIONS` item, and these violations:

```html
<div class="summary">one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone twentytwo twentythree twentyfour twentyfive twentysix.</div>
<script>
const QUESTIONS = [
  { q: "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone twentytwo twentythree twentyfour twentyfive twentysix?", options: ["12345678901234567890123456789012345678901", "short"], answer: 1, explain: "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone twentytwo twentythree twentyfour twentyfive twentysix." }
];
</script>
```

Create `test/fixtures/invalid-report.md`:

```markdown
### 요약

one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone twentytwo twentythree twentyfour twentyfive twentysix.

### 다음 섹션

This section is outside the summary check.
```

- [ ] **Step 2: Create the model-free native Codex smoke check**

Create `test/check_codex.sh`. It must print `SKIP: codex CLI unavailable` and exit 0 when `codex` is absent. Otherwise it creates a disposable Git consumer, mounts the current repository at `.codex/shared`, runs the installer, and creates an isolated Codex home that trusts only that disposable project:

```bash
codex_home="$tmp/codex-home"
mkdir -p "$codex_home"
printf '[projects."%s"]\ntrust_level = "trusted"\n' "$proj" > "$codex_home/config.toml"
```

Then execute:

```bash
CODEX_HOME="$codex_home" codex --dangerously-bypass-hook-trust --strict-config -C "$proj" debug prompt-input "Summarize active blindspot instructions."
```

Capture stdout and stderr and require exit 0, `Blindspot Mandate`, and all five skill names. Reject any parser or custom-agent configuration warning in stderr. The script does not call `codex exec`, run network diagnostics, invoke a model, or persist hook trust.

- [ ] **Step 3: Replace `test/check.sh` with the single orchestrating gate**

The top-level script must run, in order:

```bash
bash "$ROOT/test/check_agents.sh"
bash "$ROOT/test/check_skills.sh"
bash "$ROOT/test/check_installer.sh"
bash "$ROOT/test/check_active.sh"
python3 "$ROOT/skills/work-report/scripts/quiz_check.py" \
  "$ROOT/skills/work-report/templates/quiz.html" \
  "$ROOT/skills/work-report/templates/report.md" >/dev/null
if python3 "$ROOT/skills/work-report/scripts/quiz_check.py" \
  "$ROOT/test/fixtures/invalid-quiz.html" \
  "$ROOT/test/fixtures/invalid-report.md" >"$tmp/invalid.out" 2>&1; then
  fail "quiz_check.py accepted over-limit fixtures"
fi
for expected in '변경 요약' 'Q1 question' 'Q1 option' 'Q1 explain' '요약'; do
  rg -q -F "$expected" "$tmp/invalid.out" || fail "negative fixture missed $expected"
done
bash "$ROOT/test/check_codex.sh"
echo "OK: all checks passed"
```

Define `tmp="$(mktemp -d)"` and one cleanup trap at the top. Retain the exact hook-output equality check and the four-copy `25 어절` assertion either directly or through focused scripts. Do not retain any `.claude`, Markdown-agent, or `subagent_type` assertions.

- [ ] **Step 4: Run syntax checks and the complete deterministic gate**

Run: `bash -n install.sh hooks/mandate.sh test/*.sh`

Expected: exit 0.

Run: `bash test/check.sh`

Expected: focused `OK:` lines, native Codex smoke success or one explicit CLI-unavailable skip, then `OK: all checks passed`.

- [ ] **Step 5: Verify no pre-existing historical document changed**

Run:

```bash
git diff --name-status f2d473d...HEAD -- docs | awk '$1 != "A" { print; bad=1 } END { exit bad }'
```

Expected: no output and exit 0. Newly added 2026-07-29 spec/plan files are allowed because their status is `A`.

- [ ] **Step 6: Commit the integrated verification gate**

```bash
git add test/check.sh test/check_codex.sh test/fixtures
git commit -m "test: verify Codex blindspot environment"
```

---

### Task 6: Final behavior-equivalence verification and review

**Files:**
- Verify: every active file changed by Tasks 1–5
- Reference: `docs/superpowers/specs/2026-07-29-codex-port-design.md`

**Interfaces:**
- Consumes: the complete Codex-only implementation.
- Produces: fresh test evidence, an independent review verdict, and the repository's required report/quiz handoff.

- [ ] **Step 1: Run fresh repository verification**

```bash
git diff --check
bash test/check.sh
git status --short --branch
```

Expected: diff check exit 0, `OK: all checks passed`, and only intentional report/quiz artifacts if report mode has already created them.

- [ ] **Step 2: Audit active retired-host references and historical-file preservation**

```bash
bash test/check_active.sh
git diff --name-status f2d473d...HEAD -- docs | awk '$1 != "A" { print; bad=1 } END { exit bad }'
```

Expected: `OK: active Codex documentation`; no modified or deleted historical document.

- [ ] **Step 3: Request an independent code review**

Use `superpowers:requesting-code-review` with base `f2d473d` and current `HEAD`. Give the reviewer the approved spec path and require special attention to installer data preservation, hook trust/fallback behavior, custom-agent discovery, question semantics, read-only boundaries, and quiz completion gating.

Expected: no Critical or Important finding. For each such finding, write or strengthen the failing focused check, observe the failure, implement the smallest correction, rerun the focused and full suites, and commit the correction before requesting re-review.

- [ ] **Step 4: Run work-report report mode and its mechanical checker**

Invoke `$work-report` in report mode against base `f2d473d`. Generate the Korean report and 4–6 question HTML quiz under the existing `docs/blindspot/` contracts. Then run:

```bash
python3 skills/work-report/scripts/quiz_check.py \
  docs/blindspot/quiz/2026-07-29-codex-port.html \
  docs/blindspot/2026-07-29-codex-port-report.md
```

Expected: `OK`.

- [ ] **Step 5: Commit only the final report artifacts after checks pass**

```bash
git add docs/blindspot/codex-port-implementation-notes.md docs/blindspot/2026-07-29-codex-port-report.md docs/blindspot/quiz/2026-07-29-codex-port.html
git commit -m "docs: report Codex blindspot port"
```

- [ ] **Step 6: Present the quiz gate to the user**

Tell the user how to open `docs/blindspot/quiz/2026-07-29-codex-port.html`. Do not declare the work merged or complete until the user explicitly confirms a perfect score. Keep the `codex` branch local unless the user separately authorizes a push or integration action.
