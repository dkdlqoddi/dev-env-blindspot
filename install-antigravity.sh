#!/usr/bin/env bash
# Antigravity-side onboarding. Run from the consumer project root after install.sh
# (both harnesses share the submodule mounted at .claude/shared).
# Idempotent: safe to re-run after submodule updates.
set -euo pipefail
shopt -s nullglob

AG=".claude/shared/antigravity"
[[ -d "$AG/skills" ]] || { echo "error: run from the consumer project root after install.sh (needs $AG/skills)"; exit 1; }
[[ -f .claude/skills/swarm-plan/scripts/swarm_check.py ]] || { echo "error: run install.sh first — the swarm-run skill calls .claude/skills/swarm-plan/scripts/swarm_check.py"; exit 1; }

# Antigravity discovers workspace customizations under .agents/{skills,agents,rules}; link individually so
# project-local ones coexist. Links are relative: .agents/<kind>/<name> -> ../../.claude/shared/antigravity/<kind>/<name>
mkdir -p .agents/skills .agents/agents .agents/rules
for d in "$AG"/skills/*/; do
  name="$(basename "$d")"
  ln -sfn "../../$AG/skills/$name" ".agents/skills/$name"
done
for f in "$AG"/agents/*.md "$AG"/rules/*.md; do
  kind="$(basename "$(dirname "$f")")"
  ln -sfn "../../$AG/$kind/$(basename "$f")" ".agents/$kind/$(basename "$f")"
done

[[ -f .agents/skills/swarm-run/SKILL.md ]] || { echo "error: .agents/skills/swarm-run does not resolve — is the submodule initialised?"; exit 1; }
echo "blindspot-swarm: installed — .agents/{skills,agents,rules} symlinked; run /swarm-run in Antigravity (agy --add-dir \"\$PWD\" ...) once docs/swarm/plan.md exists"
