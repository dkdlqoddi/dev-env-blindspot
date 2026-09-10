#!/usr/bin/env bash
# Consumer onboarding for OpenCode. Run from the consumer project root after:
#   git submodule add <repo-url> .agents/shared
# (also supports legacy mount at .claude/shared)
# Idempotent: safe to re-run after submodule updates.
set -euo pipefail
shopt -s nullglob

if [[ -d ".agents/shared/skills" ]]; then
  SHARED=".agents/shared"
  REL_PREFIX="../shared"
  OPENCODE_PREFIX="../../.agents/shared"
elif [[ -d ".claude/shared/skills" ]]; then
  SHARED=".claude/shared"
  REL_PREFIX="../../.claude/shared"
  OPENCODE_PREFIX="../../.claude/shared"
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

# 2. symlink into .opencode/ for OpenCode discovery
mkdir -p .opencode/skills .opencode/agents .opencode/commands
for d in "$SHARED"/skills/*/; do
  name="$(basename "$d")"
  ln -sfn "$OPENCODE_PREFIX/skills/$name" ".opencode/skills/$name"
done
for f in "$SHARED"/agents/*.md; do
  name="$(basename "$f")"
  ln -sfn "$OPENCODE_PREFIX/agents/$name" ".opencode/agents/$name"
done
if [[ -d "$SHARED/.opencode/commands" ]]; then
  for f in "$SHARED"/.opencode/commands/*.md; do
    name="$(basename "$f")"
    ln -sfn "$OPENCODE_PREFIX/.opencode/commands/$name" ".opencode/commands/$name"
  done
fi

# 3. ensure opencode.jsonc exists
if [[ ! -f opencode.jsonc && -f "$SHARED/opencode.jsonc" ]]; then
  cp "$SHARED/opencode.jsonc" opencode.jsonc
fi

# 4. ensure AGENTS.md and OPENCODE.md exist and import the mandate
IMPORT_LINE="@$SHARED/MANDATE.md"
if [[ -f AGENTS.md ]]; then
  grep -qxF "$IMPORT_LINE" AGENTS.md || printf '\n%s\n' "$IMPORT_LINE" >> AGENTS.md
elif [[ -f OPENCODE.md ]]; then
  grep -qxF "$IMPORT_LINE" OPENCODE.md || printf '\n%s\n' "$IMPORT_LINE" >> OPENCODE.md
  ln -sfn OPENCODE.md AGENTS.md
else
  printf '# Project Guidelines\n\n%s\n' "$IMPORT_LINE" > AGENTS.md
  ln -sfn AGENTS.md OPENCODE.md
fi

if [[ ! -e OPENCODE.md && ! -L OPENCODE.md ]]; then
  ln -sfn AGENTS.md OPENCODE.md
fi
if [[ ! -e ANTIGRAVITY.md && ! -L ANTIGRAVITY.md ]]; then
  ln -sfn AGENTS.md ANTIGRAVITY.md
fi

echo "blindspot: installed — .agents/ & .opencode/ symlinked, AGENTS.md/OPENCODE.md import ensured"
