#!/usr/bin/env bash
# Consumer onboarding for Google Antigravity. Run from the consumer project root after:
#   git submodule add <repo-url> .agents/shared
# (also supports legacy mount at .claude/shared)
# Idempotent: safe to re-run after submodule updates.
set -euo pipefail
shopt -s nullglob

if [[ -d ".agents/shared/skills" ]]; then
  SHARED=".agents/shared"
  REL_PREFIX="../shared"
elif [[ -d ".claude/shared/skills" ]]; then
  SHARED=".claude/shared"
  REL_PREFIX="../../.claude/shared"
else
  echo "error: run from the consumer project root (needs .agents/shared/skills or .claude/shared/skills)"
  exit 1
fi

# 1. symlink skills, agents, and rules individually into .agents/
mkdir -p .agents/skills .agents/agents .agents/rules
for d in "$SHARED"/skills/*/; do
  name="$(basename "$d")"
  ln -sfn "$REL_PREFIX/skills/$name" ".agents/skills/$name"
done
for f in "$SHARED"/agents/*.md; do
  name="$(basename "$f")"
  ln -sfn "$REL_PREFIX/agents/$name" ".agents/agents/$name"
done
for f in "$SHARED"/rules/*.md; do
  name="$(basename "$f")"
  ln -sfn "$REL_PREFIX/rules/$name" ".agents/rules/$name"
done

# 2. ensure AGENTS.md and ANTIGRAVITY.md exist and import the mandate
IMPORT_LINE="@$SHARED/MANDATE.md"
if [[ -f AGENTS.md ]]; then
  grep -qxF "$IMPORT_LINE" AGENTS.md || printf '\n%s\n' "$IMPORT_LINE" >> AGENTS.md
elif [[ -f ANTIGRAVITY.md ]]; then
  grep -qxF "$IMPORT_LINE" ANTIGRAVITY.md || printf '\n%s\n' "$IMPORT_LINE" >> ANTIGRAVITY.md
  ln -sfn ANTIGRAVITY.md AGENTS.md
else
  printf '# Project Guidelines\n\n%s\n' "$IMPORT_LINE" > AGENTS.md
  ln -sfn AGENTS.md ANTIGRAVITY.md
fi

if [[ ! -e ANTIGRAVITY.md && ! -L ANTIGRAVITY.md ]]; then
  ln -sfn AGENTS.md ANTIGRAVITY.md
fi

echo "blindspot: installed — .agents/{skills,agents,rules} symlinked, AGENTS.md/ANTIGRAVITY.md import ensured"
